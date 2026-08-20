{ config, utils, ... }:
{
  programs.git = {
    enable = true;

    settings = {
      user.name = "Maciej Jur";
      user.email = "maciej@kamoshi.org";

      init.defaultBranch = "main";
      core.excludesFile = "~/.gitignore";

      sendemail = {
        smtpserver = "127.0.0.1";
        smtpuser = "maciej@kamoshi.org";
        smtpencryption = "tls";
        smtpserverport = 1025;
        smtpsslcertpath = "";
      };
    };
  };

  home.file = utils.home.symlink config [ ".gitignore" ];
}
