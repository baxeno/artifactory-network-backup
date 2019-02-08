# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2019-??-?? [Unrelease]

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
