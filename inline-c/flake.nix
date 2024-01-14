{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = {self, nixpkgs, systems, bundlers, ...}: let
    forEachSystem = func:
      builtins.foldl' 
      nixpkgs.lib.recursiveUpdate { }
      (map func (import systems));
  in forEachSystem (system: 
  
  let
    pkgs = nixpkgs.legacyPackages.${system}.extend overlay;
    
    overlay = self: super: {
      haskell = super.haskell // {
        packageOverrides = self: super: {
          inline-c-hotfix152 =
            self.callCabal2nix "inline-c" ./. { };
        };
      };
    };
    
  in {
    packages.${system} = rec { 
      default = inline-c;
      inline-c = pkgs.haskellPackages.inline-c;
      
      inline-c-shell = default.env.overrideAttrs (oldAttrs: {
        name = "inline-c";

        buildInputs = oldAttrs.buildInputs ++ (with pkgs; [
          cabal-install
          haskell-language-server
          hlint
          nil
        ]);
      });
    };

    devShells.${system}.default = self.packages.${system}.inline-c-shell;
  });
}

