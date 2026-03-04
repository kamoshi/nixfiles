#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "chardet",
# ]
# ///

import argparse
import json
import os
import shutil
import subprocess
import zipfile
from pathlib import Path
from typing import Any

import chardet


def get_audio_channel_info(file_path: str | Path) -> tuple[int, str]:
    """Returns the number of channels and the channel layout string of the first audio stream."""
    cmd = [
        "ffprobe",
        "-v",
        "error",
        "-select_streams",
        "a:0",
        "-show_entries",
        "stream=channels,channel_layout",
        "-of",
        "json",
        str(file_path),
    ]

    try:
        result = subprocess.run(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True
        )
        data = json.loads(result.stdout)

        if not data.get("streams"):
            return 2, "unknown"

        stream = data["streams"][0]
        channels = stream.get("channels", 2)
        channel_layout = stream.get("channel_layout", "unknown")

        return channels, channel_layout

    except (subprocess.CalledProcessError, json.JSONDecodeError, KeyError) as e:
        print(f"Warning: Could not analyze audio channels: {e}")
        return 2, "unknown"


def get_encoding(file_path: str | Path) -> str:
    with open(file_path, "rb") as f:
        raw_data: bytes = f.read()
    result = chardet.detect(raw_data)
    encoding = result.get("encoding")
    return encoding if isinstance(encoding, str) else "utf-8"


def parse_time(time_str: str) -> float:
    """Parses CUE time MM:SS:FF into seconds"""
    parts: list[str] = time_str.split(":")
    if len(parts) == 3:
        m, s, f = map(int, parts)
        return m * 60 + s + f / 75.0
    return 0.0


def fix_zip_filename(info: zipfile.ZipInfo) -> str:
    """Attempt to fix Japanese filename encodings inside the zip."""
    original: str = info.filename
    try:
        # If the filename was encoded in Shift-JIS but read as CP437
        fixed: str = original.encode("cp437").decode("shift_jis")
        return fixed
    except Exception:
        pass

    try:
        # If it was UTF-8 but read as CP437
        fixed = original.encode("cp437").decode("utf-8")
        return fixed
    except Exception:
        pass

    return original


def split_flac_with_cue(
    cue_path: str | Path,
    flac_path: str | Path,
    output_dir: str | Path,
    transcode_opus: bool = False,
) -> None:
    encoding: str = get_encoding(cue_path)
    print(f"Detected CUE encoding: {encoding}")

    opus_bitrate = "192k"
    if transcode_opus:
        channels, layout = get_audio_channel_info(flac_path)
        if channels > 2:
            print(
                f"Detected multi-channel audio ({channels} channels, layout: {layout}). Using 256k bitrate for Opus."
            )
            opus_bitrate = "256k"
        else:
            print(
                f"Detected standard audio ({channels} channels, layout: {layout}). Using 192k bitrate for Opus."
            )

    with open(cue_path, "r", encoding=encoding, errors="replace") as f:
        lines: list[str] = f.readlines()

    tracks: list[dict[str, Any]] = []
    current_track: dict[str, Any] | None = None
    album_performer: str = "Unknown Artist"
    album_title: str = "Unknown Album"
    album_date: str | None = None
    album_genre: str | None = None
    album_composer: str | None = None

    for line in lines:
        line = line.strip()
        match line.split(maxsplit=1):
            case ["REM", val]:
                parts: list[str] = val.split(maxsplit=1)
                if len(parts) == 2:
                    rem_type, rem_val = parts
                    clean_val: str = rem_val.strip('"')
                    if rem_type == "DATE":
                        if current_track is None:
                            album_date = clean_val
                        else:
                            current_track["date"] = clean_val
                    elif rem_type == "GENRE":
                        if current_track is None:
                            album_genre = clean_val
                        else:
                            current_track["genre"] = clean_val
            case ["PERFORMER", val]:
                clean_val = val.strip('"')
                if current_track is None:
                    album_performer = clean_val
                else:
                    current_track["performer"] = clean_val
            case ["TITLE", val]:
                clean_val = val.strip('"')
                if current_track is None:
                    album_title = clean_val
                else:
                    current_track["title"] = clean_val
            case ["COMPOSER", val]:
                clean_val = val.strip('"')
                if current_track is None:
                    album_composer = clean_val
                else:
                    current_track["composer"] = clean_val
            case ["ISRC", val]:
                if current_track:
                    current_track["isrc"] = val.strip('"')
            case ["TRACK", val]:
                if current_track and "start_time" in current_track:
                    tracks.append(current_track)
                track_num: str = val.split()[0]
                current_track = {
                    "number": track_num,
                    "title": f"Track {track_num}",
                    "performer": album_performer,
                }
            case ["INDEX", val] if current_track and val.startswith("01"):
                time_parts: list[str] = val.split()
                if len(time_parts) > 1:
                    current_track["start_time"] = parse_time(time_parts[1])

    if current_track and "start_time" in current_track:
        tracks.append(current_track)

    for i in range(len(tracks) - 1):
        tracks[i]["end_time"] = tracks[i + 1]["start_time"]

    os.makedirs(output_dir, exist_ok=True)

    print(f"Found {len(tracks)} tracks. Splitting...")
    for track in tracks:
        # Sanitize filename
        safe_title: str = "".join(c for c in track["title"] if c not in r'\/:*?"<>|')
        ext: str = "opus" if transcode_opus else "flac"
        out_filename: str = f"{track['number']} - {safe_title}.{ext}"
        out_filepath: str = os.path.join(output_dir, out_filename)

        cmd: list[str] = [
            "ffmpeg",
            "-y",
            "-i",
            str(flac_path),
            "-ss",
            str(track["start_time"]),
        ]
        if "end_time" in track:
            cmd.extend(["-to", str(track["end_time"])])

        if transcode_opus:
            cmd.extend(["-c:a", "libopus", "-b:a", opus_bitrate])
        else:
            cmd.extend(["-c:a", "flac"])

        cmd.extend(
            [
                "-metadata",
                f"title={track['title']}",
                "-metadata",
                f"track={track['number']}",
                "-metadata",
                f"artist={track['performer']}",
                "-metadata",
                f"album={album_title}",
            ]
        )

        date: str | None = track.get("date") or album_date
        if date:
            cmd.extend(["-metadata", f"date={date}"])

        genre: str | None = track.get("genre") or album_genre
        if genre:
            cmd.extend(["-metadata", f"genre={genre}"])

        composer: str | None = track.get("composer") or album_composer
        if composer:
            cmd.extend(["-metadata", f"composer={composer}"])

        if "isrc" in track:
            cmd.extend(["-metadata", f"isrc={track['isrc']}"])

        cmd.append(out_filepath)

        print(f"Extracting: {out_filename}")
        try:
            subprocess.run(
                cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, check=True
            )
        except subprocess.CalledProcessError as e:
            if e.stderr:
                print(
                    f"Error extracting {out_filename}: {e.stderr.decode('utf-8', errors='replace')}"
                )
            else:
                print(f"Error extracting {out_filename}: {e}")


def process_standalone_flacs(
    flac_files: list[str],
    output_dir: str | Path,
    transcode_opus: bool = False,
) -> None:
    os.makedirs(output_dir, exist_ok=True)

    if not transcode_opus:
        print(
            f"No CUE found and --opus not specified. Copying {len(flac_files)} FLAC files to '{output_dir}'..."
        )
        for flac_path in flac_files:
            dest_path: str = os.path.join(output_dir, Path(flac_path).name)
            if not os.path.exists(dest_path):
                shutil.copy2(flac_path, dest_path)
                print(f"Copied: {Path(flac_path).name}")
        return

    print(f"No CUE found. Transcoding {len(flac_files)} FLAC files to Opus...")
    for flac_path in flac_files:
        channels, layout = get_audio_channel_info(flac_path)
        opus_bitrate: str = "256k" if channels > 2 else "192k"

        out_filename: str = Path(flac_path).with_suffix(".opus").name
        out_filepath: str = os.path.join(output_dir, out_filename)

        cmd: list[str] = [
            "ffmpeg",
            "-y",
            "-i",
            str(flac_path),
            "-map_metadata",
            "0",
            "-c:a",
            "libopus",
            "-b:a",
            opus_bitrate,
            out_filepath,
        ]

        print(
            f"Transcoding: {Path(flac_path).name} ({channels} channels) -> {out_filename}"
        )
        try:
            subprocess.run(
                cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, check=True
            )
        except subprocess.CalledProcessError as e:
            if e.stderr:
                print(
                    f"Error transcoding {out_filename}: {e.stderr.decode('utf-8', errors='replace')}"
                )
            else:
                print(f"Error transcoding {out_filename}: {e}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Extract and split FLAC from a zip file using a CUE sheet."
    )
    parser.add_argument(
        "zip_file",
        nargs="?",
        default=None,
        help="The zip file containing the FLAC and CUE files.",
    )
    parser.add_argument(
        "--opus",
        action="store_true",
        help="Transcode output to Opus instead of FLAC. Automatically uses 256k for 5.1 audio, 192k otherwise.",
    )
    parser.add_argument(
        "--copy-images",
        action="store_true",
        help="Copy image files (cover art) from the extracted archive to the final directory.",
    )
    args = parser.parse_args()

    if args.zip_file:
        zip_file: str = args.zip_file
    else:
        # Find the first zip file in the current directory
        zip_files: list[Path] = list(Path(".").glob("*.zip"))
        if not zip_files:
            print("No .zip file found in the current directory!")
            return
        zip_file = str(zip_files[0])

    base_name: str = os.path.splitext(zip_file)[0]
    temp_dir: str = base_name + ".temp"
    final_dir: str = base_name

    print(f"Extracting '{zip_file}' to '{temp_dir}'...")
    try:
        with zipfile.ZipFile(zip_file, "r") as zf:
            for info in zf.infolist():
                info.filename = fix_zip_filename(info)
                zf.extract(info, temp_dir)
    except Exception as e:
        print(f"Failed to extract zip file: {e}")
        return

    # Search for CUE and FLAC files in the temp directory
    cue_files: list[str] = [str(p) for p in Path(temp_dir).rglob("*.cue")]
    flac_files: list[str] = [str(p) for p in Path(temp_dir).rglob("*.flac")]

    if not flac_files:
        print("No .flac file found in the extracted archive!")
        return

    # Check if ffmpeg is installed
    if shutil.which("ffmpeg") is None:
        print("\nERROR: 'ffmpeg' is not installed or not in PATH.")
        print(
            "Please install ffmpeg (e.g., 'brew install ffmpeg' on macOS) to process audio files."
        )
        return

    # Create the final directory
    os.makedirs(final_dir, exist_ok=True)

    if cue_files:
        # Assume the first found files are the ones we want
        cue_path: str = cue_files[0]
        flac_path: str = flac_files[0]

        print(f"Found CUE: {cue_path}")
        print(f"Found FLAC: {flac_path}")

        # Split the FLAC files directly into the final directory
        print(f"\nSplitting tracks directly into '{final_dir}'...")
        split_flac_with_cue(cue_path, flac_path, final_dir, args.opus)
    else:
        process_standalone_flacs(flac_files, final_dir, args.opus)

    # Copy all images (like cover art) from temp_dir to final_dir
    if args.copy_images:
        print(f"\nCopying images to '{final_dir}'...")
        image_extensions: list[str] = [
            "*.jpg",
            "*.jpeg",
            "*.png",
            "*.bmp",
            "*.gif",
            "*.webp",
        ]
        for ext in image_extensions:
            for img_path in Path(temp_dir).rglob(ext):
                # Ignore case by also checking uppercase extensions just in case, though rglob is case-sensitive on Linux/sometimes macOS
                dest_path: str = os.path.join(final_dir, img_path.name)
                # Only copy if it doesn't already exist to prevent overwriting with duplicates if any
                if not os.path.exists(dest_path):
                    shutil.copy2(img_path, dest_path)
                    print(f"Copied: {img_path.name}")
    else:
        print("\nSkipping image copy (use --copy-images to include them).")

    # Clean up the temporary directory
    print(f"\nCleaning up temporary directory '{temp_dir}'...")
    try:
        shutil.rmtree(temp_dir)
        print("Cleanup successful.")
    except Exception as e:
        print(f"Warning: Failed to clean up temp directory: {e}")

    print(f"\nAll done! Folder '{final_dir}' is ready for Jellyfin.")


if __name__ == "__main__":
    main()
