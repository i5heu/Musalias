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
- **recomp** - will pull, down and up as deamon a docker compose, will remove orphans, and follow logs after up

### Filesystem 
- **lh** - Listing all files with human-readable sizes
- **dud** - Display the size of all folders in the current directory, sorted by size
- **showContents** - Display all file contents in the current directory recursively   
Options:
   - **-c** Clean content by removing excessive whitespace and line breaks
   - **-e** Comma-separated list of glob patterns to exclude (overrides default excludes)
- **tazstd** - Function to tar and compress a directory with ZSTD, $0 <directory> is required
- **mkdid** - Function to create directories recursively and navigate to the deepest directory, $0 <directory> is required

### System Administration 
- **up** - Update, upgrade, dis-upgrade, and autoremove packages 👑
- **install_default** - Install default packages: docker.io, docker-compose-v2, htop, iftop 👑

### Aliases (this script) Related 
- **laa** - Alias for listAliases script
- **aliasesList** - Alias for listAliases script
- **listAliases** - List all available aliases and functions with their descriptions   
Options:
   - **-v** will show the aliases file
   - **-m** will print in markdown format
- **aliasup** - Update the aliases collection on your system

## Legend
Aliase marked with 👑 will call sudo

## Install Aliases
Go to homefolder and run this
```bash
git clone https://github.com/i5heu/Musalias.git ~/.aliases && bash ~/.aliases/setup.sh && source ~/.aliases/aliases
```

To update use
```base
aliasup
```
