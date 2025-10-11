# Musalias: i5heu's Aliases
This is a collection of aliases and functions that I use.  
A easy way to update these scripts is provided with `aliasup`.  
Tools for Documentation are also included.  

Musalias = Muse + aliases  

[Install Aliases](#install-aliases)  
[Legend](#Legend)


## Aliases


### Kubernetes 
- **k** - kubectl command shortcut that will use kubectl if available, otherwise it will use microk8s kubectl
- **kubectl** - kubectl will use kubectl if available, otherwise it will use microk8s kubectl 
- **kpf** - shortcut to get rollout restart
- **kls** - shortcut to get all pods in all namespaces
- **ksv** - shortcut to get all services in all namespaces
- **kdp** - shortcut to get all deployments in all namespaces
- **kn** - shortcut to get all nodes
- **kns** - shortcut to get all namespaces
- **kdh** - shortcut to get rollout history
- **kds** - shortcut to get rollout status

### MicroK8s 
- **m8** - Starting MicroK8s
- **m8dp** - Accessing the MicroK8s dashboard proxy
- **install_microk8** - Install MicroK8s by running the install script

### Docker 
- **dc** - shortcut for docker-compose or docker compose
- **dcl** - shortcut for docker-compose or docker compose logs -f -n 500
- **dcls** - If fzf is available you'll get a fuzzy selector; otherwise a numbered menu.
- **recomp** - will pull, down and up as deamon a docker compose, will remove orphans, and follow logs after up
- **recompBuild** - will pull, build, down and up as deamon a docker compose, will remove orphans, and follow logs after up

### Filesystem 
- **lh** - Listing all files with human-readable sizes
- **dud** - Display the size of all folders in the current directory, sorted by size
- **showContents** - Display all file contents in the current directory recursively and write to showContentsOutput.txt   
Options:
   - **-c** Clean content by removing excessive whitespace and line breaks
   - **-e** Comma-separated list of glob patterns to exclude (overrides default excludes)
- **serve** - Serve the current directory over HTTP.   
Options:
   - **-n** Dry-run: print chosen port and exit
   - **-p** <port> Start searching from specified port (default 8080)
- **tazstd** - Function to tar and compress a directory with ZSTD, $0 <directory> is required
- **mkdid** - Function to create directories recursively and navigate to the deepest directory, $0 <directory> is required

### System Administration 
- **up** - Update, upgrade, dis-upgrade, and autoremove packages 👑
- **install_default** - Install default packages one by one (docker.io, docker-compose-v2, htop, iftop, fzf, bottom) if some fail it shows a summary of failed installs at the end. 👑   
Options:
   - **--no-snap** Skip installing bottom via snap.
   - **--dry-run** Print what would be done, but do not execute.

### Aliases (this script) Related 
- **laa** - Alias for listAliases script
- **aliasesList** - Alias for listAliases script
- **listAliases** - List all available aliases and functions with their descriptions in fzf with fallback to less   
Options:
   - **-v** will show the aliases file not interactive
   - **-m** will print in markdown format not interactive
- **aliasup** - Update the aliases collection on your system
- **musaliasUpdateReadme** - replace the Aliases section in ~/.Musalias/scripts/README.md with the current listAliases -m output

### Legend
Aliase marked with 👑 will call sudo

## Install Aliases
Go to homefolder and run this
```bash
git clone https://github.com/i5heu/Musalias.git ~/.Musalias && bash ~/.Musalias/setup.sh && source ~/.Musalias/aliases
```

Or with SSH
```bash
git clone git@github.com:i5heu/Musalias.git ~/.Musalias && bash ~/.Musalias/setup.sh && source ~/.Musalias/aliases
```

To update use
```base
aliasup
```
