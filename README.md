### MAC and LINUX bash

### Prepare LINUX build
tar -cvzf cfglx.tar.gz ./lx/.bashrc ./lx/.bashrc/.bashrc.d/

### Prepare MAC build
cd mc/zsh
tar -cvzf ../../cfgmc.tar.gz .zshrc .zshrc.d/

```
-c: Creates a new archive.
-v: (Optional) Enables verbose mode, showing the files being processed.
-z: Compresses the archive using gzip.
-f archive_name.tar.gz: Specifies the name of the resulting archive
```

### Install
tar -xvzf cfgmc.tar.gz
    or
tar -xvzf cfglx.tar.gz

```
-x: Stands for "extract." This option tells tar to extract the contents of an archive.
-v: Stands for "verbose." This option makes tar list the files as they are being extracted, so you can see what's happening in real-time.
-z: Tells tar to filter the archive through gzip (i.e., to decompress a .gz archive). This is necessary when dealing with files that have been compressed with gzip, typically those ending in .tar.gz or .tgz.
-f: Specifies the name of the archive file to be processed. The filename should immediately follow this option.
--overwrite: default
```


ource .zshrc
