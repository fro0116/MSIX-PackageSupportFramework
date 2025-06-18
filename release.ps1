$version = "v2025.06.09-3"
$release_directory = "template-release-$version"
$debug_directory = "template-debug-$version"
New-Item -ItemType Directory -Force -Path $release_directory
Remove-Item -Recurse $release_directory/*
Copy-Item -Recurse Win32/Release/* $release_directory/
Copy-Item -Recurse -Force x64/Release/* $release_directory/
Copy-Item -Recurse $release_directory/x86/* $release_directory/
Copy-Item -Recurse $release_directory/amd64/* $release_directory/
Remove-Item $release_directory/*.pdb
Remove-Item $release_directory/*.exp
Remove-Item $release_directory/*.lib
Remove-Item $release_directory/*.idb
Remove-Item $release_directory/PsfMonitor.exe.config
Remove-Item -Recurse $release_directory/x86
Remove-Item -Recurse $release_directory/amd64
Copy-Item -Recurse runtimes/Release/* $release_directory/
New-Item -Path $release_directory/template-version.txt -ItemType File -Value "release-$version"

New-Item -ItemType Directory -Force -Path $debug_directory
Remove-Item -Recurse $debug_directory/*
Copy-Item -Recurse Win32/Debug/* $debug_directory/
Copy-Item -Recurse -Force x64/Debug/* $debug_directory/
Copy-Item -Recurse $debug_directory/x86/* $debug_directory/
Copy-Item -Recurse $debug_directory/amd64/* $debug_directory/
Remove-Item $debug_directory/*.pdb
Remove-Item $debug_directory/*.exp
Remove-Item $debug_directory/*.lib
Remove-Item $debug_directory/*.idb
Remove-Item $debug_directory/PsfMonitor.exe.config
Remove-Item -Recurse $debug_directory/x86
Remove-Item -Recurse $debug_directory/amd64
Copy-Item -Recurse runtimes/Debug/* $debug_directory/
New-Item -Path $debug_directory/template-version.txt -ItemType File -Value "debug-$version"
