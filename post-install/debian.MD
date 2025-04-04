# Install Debian
1. Install Debian without any desktop environment.  

# After installation
1. Login and switch to root using su
```bash
su
```

2. Update apt
```bash
apt update
```

3. Install desktop and packages
```bash
apt install \
  gnome-session \
  gnome-core
```

4 MV /etc/network/interfaces.bak
