# BASH-BERRY 🚀

A simple set of shell scripts for cloning my device repositories, setting up Git configs, and installing GPG keys.

## Quick start

### Direct one-liner execution

Clone device repositories:

```bash
wget -q https://raw.githubusercontent.com/ihsanulrahman/bash-berry/test/repo_clone.sh -O - | bash
```

Set up Git configs and GPG keys:

```bash
wget -q https://raw.githubusercontent.com/ihsanulrahman/bash-berry/main/git-gpg.sh -O - | bash
```

Notes
- These are convenience one-liners that download and execute remote scripts. Review the scripts before running them.
- Ensure you have wget and bash installed on your system.
