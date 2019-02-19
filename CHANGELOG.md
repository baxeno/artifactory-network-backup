# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2019-xx-xx [Unrelease]

### Added

- Restore script is idempotent.
- Added configration file parameter BACKUP_COUNT (was in artifact-backup.sh)
- Added configration file parameter CIFS_VERSION (was in artifact-backup.sh)

### Changed

- Renamed configuration file parameter FULL_LOCAL_DIR (before: FULL_SRC_DIR)
- Renamed configuration file parameter REMOTE_DIR (before: DEST_DIR)

## [0.1.0] - 2019-02-14

### Added

- MIT license file.
- Tarball weekly backup so it will survive NTFS.
- Mount CIFS/SMB network share using `live-cfg.sh` configuration file.
- Template configuration file (`template-cfg.sh`).
- Backup script is idempotent.
- Abort if Aritfactory is creating weekly backup files and ignore daily backup files.
- Support different version of Windows.
- Cleanup old network backups.
- Setup crontab examples.
