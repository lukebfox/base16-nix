# Base16 themes for Home Manager
This Nix flake exports a Home Manager module for managing colour schemes.

## Usage
N.b. this example roughly reflects the usage of @atpotts, but I haven't tried to use it, so there may be typos / bugs
```nix
{ config, pkgs, lib, ... }:
{
  config = {

    # Choose your theme
    themes.base16 = {
      enable = true;
      scheme = "solarized";
      variant = "solarized-dark";

      # Add extra variables for inclusion in custom templates
      extraParams = {
        fontname = mkDefault  "Inconsolata LGC for Powerline";
        headerfontname = mkDefault  "Cabin";
        bodysize = mkDefault  "10";
        headersize = mkDefault  "12";
        xdpi= mkDefault ''
          Xft.hintstyle: hintfull
        '';
      };
    };

    # 1. Use pre-provided templates
    ###############################

    programs.bash.initExtra = ''
      source ${config.lib.base16.base16template "shell"}
    '';
    home.file.".vim/colors/mycolorscheme.vim".source =
      config.lib.base16.base16template "vim";

    # 2. Use your own templates
    ###########################

    home.file.".Xresources".source = config.lib.base16.template {
      src = ./examples/Xresources;
    };
    home.file.".xmonad/xmobarrc".source = config.lib.base16.template {
      src = ./examples/xmobarrc;
    };

    # 3. Template strings directly into other home-manager configuration
    ####################################################################

    services.dunst = {
        enable = true;
        settings = with config.lib.base16.theme;
            {
              global = {
                geometry         =  "600x1-800+-3";
                font             = "${headerfontname} ${headersize}";
                icon_path =
                  config.services.dunst.settings.global.icon_folders;
                alignment        = "right";
                frame_width      = 0;
                separator_height = 0;
                sort             = true;
              };
              urgency_low = {
                background = "#${base01-hex}";
                foreground = "#${base03-hex}";
              };
              urgency_normal = {
                background = "#${base01-hex}";
                foreground = "#${base05-hex}";
              };
              urgency_critical = {
                msg_urgency = "CRITICAL";
                background  = "#${base01-hex}";
                foreground  = "#${base08-hex}";
              };
        };
     };
  };
}
```
## Flakes
If you package your NixOS configuration(s) via flakes, you can easily import this module. The following example shows how to add custom modules to home-manager including the one exported by this flake.
```nix
{

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.03";
    home.url    = "github:nix-community/home-manager";
    base16.url  = "github:lukebfox/base16-nix";
  };
  outputs = inputs:
    nixosConfigurations.hostname = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
	  specialArgs = { inherit inputs; };
      modules = [

        inputs.home.nixosModules.home-manager
		
        ({config, ... }:
		 {
		   # Will merge submodule definitions
	       options.home-manager.users = lib.mkOption {
             type = lib.types.attrsOf (lib.types.submoduleWith {

               # Define any extra Home Manager modules you want here.
               modules = [ inputs.base16.hmModule.base16 ];
			   
               # Makes specialArgs available to Home Manager modules as well.
               specialArgs = specialArgs // {
	             # Allow accessing the parent NixOS configuration.
                 super = config;
               };
             });
         })

	  ];
    };
}
```
For a less contrived example, you can browse my Nix configuration files [here](https://github/lukebfox/nix-infrastructure).

## Reloading

Changing themes involves switching the theme definition and typing `nixos-rebuild switch` on NixOS
or `home-manager switch` otherwise. There is no attempt in general to force programs to
reload, and not all are able to reload their configs, although I have found
that occasionally restarting applications has been
enough.

You are unlikely to achieve a complete switch without logging out and logging back
in again.

## Todo

Provide better support for custom schemes (currently this assumes you'll
want to use something in the base16 repositories, but there is no reason
for this).

## Updating Sources

I will update this repository regularly, although if you want the absolute latest themes, you can fork this repository and from the project root run
```
$ nix develop
$ update-base16
```
then, point your flake's base16 input to your fork and you are good to go.
