# Artifactory CIFS/SMB network backup
[![Build Status](https://travis-ci.org/baxeno/artifactory-network-backup.svg?branch=master)](https://travis-ci.org/baxeno/artifactory-network-backup)

Transfers Artifactory weekly backup from a Linux environment to a CIFS/SMB network share (Windows environment).
The SMB/CIFS protocol is a standard file sharing protocol widely deployed on Microsoft Windows machines.
A weekly backup typically contain locally promoted artifacts and exclude cached remote artifacts.
In case you need to maintain a code base for an extended period or backup size does not matter, just include all binary repositories.
Artifactory can be configured to automatically cleanup old local backups.

**Features:**

- Tarball weekly backup. _(makes backup compatible with NTFS)_
- Mount CIFS/SMB network share. _(does not use `/etc/fstab`)_
- Idempotent backup. _(nothing will happen if called repeatedly)_
- Abort if Aritfactory is creating weekly backup files. _(daily backup can run simultaneous)_
- Support different version of Windows. _(see `CIFS_VERSION` configuration)_
- Cleanup old network backups. _(avoid out-of-space on network share)_
- Setup crontab.

# Prerequisites

- JFrog Artifactory Pro instance (ex. docker-compose on Linux)
- Weekly backup enabled (Admin -> Backup)
- Host tools
  - Fedora: `sudo dnf install bash tar cifs-utils crontabs`
- Kernel cifs driver.

> Note: Artifactory OSS is also technically support but it does not support promotion.

# Configurations

Create a configuration file called `live-cfg.sh` based on `template-cfg.sh`.

**AD_USER** - Active Directory username for CIFS/SMB network share.

**AD_PW** - Active Directory password for CIFS/SMB network share.

**AD_DOMAIN** - Active Directory domain name for CIFS/SMB network share.

**AD_MACHINE** - Active Directory machine name for CIFS/SMB network share.

**MOUNT_POINT** - Linux mount point for CIFS/SMB network share.

**DEST_DIR** - Backup destination directory structure relative to MOUNT_POINT. Optional and may be left empty.

**FULL_SRC_DIR** - Absolute path to Linux directory with Artifactory weekly backups.

**CIFS_VERSION** - SMB protocol version (default=3.0). Allowed values are:
  - 1.0 - The classic CIFS/SMBv1 protocol.
  - 2.0 - The SMBv2.002 protocol. This was initially introduced in Windows Vista Service Pack 1, and Windows Server 2008.
  Note that the initial release version of Windows Vista spoke a slightly different dialect (2.000) that is not supported.
  - 2.1 - The SMBv2.1 protocol that was introduced in Microsoft Windows 7 and Windows Server 2008R2.
  - 3.0 - The SMBv3.0 protocol that was introduced in Microsoft Windows 8 and Windows Server 2012.
  - 3.1.1 or 3.11 - The SMBv3.1.1 protocol that was introduced in Microsoft Windows Server 2016.

**BACKUP_COUNT** - How many network backups must be kept. (default 2)

> CIFS/SMB protocol information from `man mount.cifs`.

# Configure periodically run


**Crontab syntax:**

```
*     *     *   *    *        command to be executed
-     -     -   -    -
|     |     |   |    |
|     |     |   |    +----- day of week (0 - 6) (Sunday=0)
|     |     |   +------- month (1 - 12)
|     |     +--------- day of month (1 - 31)
|     +----------- hour (0 - 23)
+------------- min (0 - 59)
```

> [crontab guru](https://crontab.guru/) - The quick and simple editor for cron schedule expressions by Cronitor.

# Test

You should be able to run `./run_test.sh` and validate that `artifact-backup.sh` is working on host machine without doing remote connections.
