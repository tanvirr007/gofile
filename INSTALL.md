### A Simple Script to upload Files to https://gofile.io via Terminal (CLI)

#### Usage Instructions for Linux Environment:

- To make the script globally available, run the following commands in your terminal:
```bash
   sudo wget https://raw.githubusercontent.com/tanvirr007/gofile/main/gofile.sh -O "/usr/local/bin/gofile"
   sudo chmod +x /usr/local/bin/gofile
```

- To uninstall gofile, you can run:
```bash
   sudo rm "/usr/local/bin/gofile"
```


#### Usage Instructions for Termux:

-  Download this script using wget:
```bash
   wget https://raw.githubusercontent.com/tanvirr007/gofile/main/gofile.sh -O "/data/data/com.termux/files/usr/bin/gofile" && chmod +x "/data/data/com.termux/files/usr/bin/gofile"
```

- To uninstall gofile from Termux, you can run:
```bash
   rm "/data/data/com.termux/files/usr/bin/gofile"
```


#### How to Upload Files:

1. Run the script with the file(s) you want to upload:
```bash
   gofile your_filename
```

2. You can upload multiple files by specifying their names separated by spaces:
```bash
   gofile file1 file2 file3
```

3. If you have long filenames, you can use wildcards like:
```bash
   gofile So*.zip
```
```bash
   gofile SomethingOS*.zip
```
