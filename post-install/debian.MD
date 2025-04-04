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
  gnome-core \
  git
```

4. Reboot
```bash
shutdown -r now
```

5. Fix network
After the restart, login, open the terminal.
```bash
su
```

```bash
mv /etc/network/interfaces /etc/network/interfaces.bak
```

After the restart, the wired or wireless network should work.

# Post install (ansible)
