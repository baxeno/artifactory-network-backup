# Artifactory CIFS/SMB network backup solution

[![Build Status](https://travis-ci.org/baxeno/artifactory-network-backup.svg?branch=master)](https://travis-ci.org/baxeno/artifactory-network-backup)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/baxeno/artifactory-network-backup/blob/master/LICENSE)

This tool transfers JFrog Artifactory weekly backup from a Linux environment to a CIFS/SMB network share (Windows environment).
The SMB/CIFS protocol is a standard file sharing protocol widely deployed on Microsoft Windows machines.
Keeping a backup of all promoted and/or released artifacts are very useful in case you need to maintain a code base for an extended period of time even decades.
Artifactory can be configured to automatically cleanup old local backups (daily and weekly) so this tools does not implement local cleanup but only remote cleanup.

:heavy_plus_sign: Weekly backup typically include:

- Promoted artifacts like Docker, Maven, NuGet, etc.
- Manually published Maven artifacts using [maven-noci-publiser](https://github.com/baxeno/maven-noci-publisher) as it's a good generic binary container.

:o: Weekly backup for long-term maintenance projects include:

- Cached remote artifacts like RPM, Maven jcenter, Gradle plugins, NuGet, etc.

:heavy_minus_sign: Weekly backup typically exclude:

- Non-promoted builds like Maven SNAPSHOTs, etc.

**:star: Features :star:**

- Tarball weekly backup. _(makes backup compatible with NTFS)_
- Mount CIFS/SMB network share. _(does not use `/etc/fstab`)_
- Idempotent backup and restore. _(nothing will happen if called repeatedly)_
- Abort if Aritfactory is creating weekly backup files. _(daily backup can run simultaneous)_
- Support different version of Windows. _(see `CIFS_VERSION` configuration)_
- Cleanup old network backups. _(avoid out-of-space on network share)_
- Setup crontab.

## :factory: Deploy to production

1. See _Prerequisites_ section.
1. Clone/fork this repository.
1. Run test script, see _Test_ section.
1. Create private `live-cfg.sh`, see _Configuration paramters_ section.
1. Schedule periodic run, see _Setting up cron job_ section

> :information_source: Minimum install requires: `artifact-backup.sh`, `artifact-restore.sh`, `common.sh`, `live-cfg.sh` (modified `template-cfg.sh`).

## :frog: Prerequisites

- JFrog Artifactory Pro instance (ex. docker-compose on Linux)
- Weekly backup enabled in Artifactory (Admin -> Backup)
- Host tools
  - Fedora: `sudo dnf install bash tar cifs-utils crontabs`
- Kernel cifs driver

> :exclamation: Artifactory OSS is also technically supported but it does not support promotion.

> :exclamation: When running Artifactory in docker you must volume mount backup directory to host.

## :vertical_traffic_light: Configuration parameters

:point_right: Create a configuration file called `live-cfg.sh` based on `template-cfg.sh`. :point_left:

- **AD_USER** - Active Directory username for CIFS/SMB network share.
- **AD_PW** - Active Directory password for CIFS/SMB network share.
- **AD_DOMAIN** - Active Directory domain name for CIFS/SMB network share.
- **AD_MACHINE** - Active Directory machine name for CIFS/SMB network share.
- **MOUNT_POINT** - Linux mount point for CIFS/SMB network share.
- **DEST_DIR** - Backup destination directory structure relative to MOUNT_POINT. Optional and may be left empty.
- **FULL_SRC_DIR** - Absolute path to Linux directory with Artifactory weekly backups.
- **CIFS_VERSION** - SMB protocol version. Allowed values are [default 3.0]:
  - 1.0 - The classic CIFS/SMBv1 protocol.
  - 2.0 - The SMBv2.002 protocol. This was initially introduced in Windows Vista Service Pack 1, and Windows Server 2008.
  Note that the initial release version of Windows Vista spoke a slightly different dialect (2.000) that is not supported.
  - 2.1 - The SMBv2.1 protocol that was introduced in Microsoft Windows 7 and Windows Server 2008R2.
  - 3.0 - The SMBv3.0 protocol that was introduced in Microsoft Windows 8 and Windows Server 2012.
  - 3.1.1 or 3.11 - The SMBv3.1.1 protocol that was introduced in Microsoft Windows Server 2016.
- **BACKUP_COUNT** - How many network backups must be kept. [default 2; minimum 1]

> :information_source: CIFS/SMB protocol information from `man mount.cifs`.

> :warning: Disk space peak usage: (`BACKUP_COUNT` + 1 ) * `backup size`.

## :clock6: Setting up cron job

You should schedule a daily run of the script to ensure the latest weekly backup is copied to the network share.
Choose a start time that don't collide with network share backup and machine maintenance window (patches are applied and rebooted).
Call `sudo crontab -e` and use examples below as template.

**Examples:**

The following examples are running daily at 06:00 and this repository `artifactory-network-backup` is cloned into `/home/devops/anb`.

_Run daily with log:_

`0 6 * * * /home/devops/anb/artifact-backup.sh >> /home/devops/anb/log.txt 2>&1`

_Run daily without log:_

`0 6 * * * /home/devops/anb/artifact-backup.sh > /dev/null 2>&1`

> :information_source: It's possible to enable development debug in `artifact-backup.sh` by setting `set -x`.

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

> :information_source: [crontab guru](https://crontab.guru/) - The quick and simple editor for cron schedule expressions by Cronitor.

## :construction: Development

What to help? See [CONTRIBUTING.md](CONTRIBUTING.md).

All notable changes to this project will be documented in [CHANGELOG.md](CHANGELOG.md).

Version string is stored in [common.sh](common.sh).

**Interface:**

The following items are considered interfaces of this component:

- Backup directory format created by Artifactory - `YYYYMMDD.HHMMSS`
- Variables in `template-cfg.sh`

> :warning: Major version must be bumped in case any changes breaks the interface. :boom:

**Travis pipeline:**

- [ShellCheck](https://github.com/koalaman/shellcheck)
- [Self test](run_test.sh)

**Test:**

You should be able to run `./run_test.sh` and validate that `artifact-backup.sh` is working on host machine without doing remote connections.

**Documentation:**

[Complete list of github markdown emoji markup](https://gist.github.com/rxaviers/7360908)
