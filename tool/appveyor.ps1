# Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
# All rights reserved. Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

param([string]$action)

function throw_if_process_failed {
    param([string]$message)
    if ($LASTEXITCODE -ne 0) { throw $message }
}

function install {
    start-filedownload https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-windows-x64-release.zip
    7z.exe x dartsdk-windows-x64-release.zip -oc:\ | select-string "^Extracting" -notmatch
    throw_if_process_failed "could not extract sdk"
    write-output ""

    # Redirect an coerce into string so that Appveyor doesn't print this in red.
    "$(c:\dart-sdk\bin\dart --version 2>&1)"
}

function test {
    # Set up the path.
    $env:PATH = "c:\dart-sdk\bin;$env:PATH;C:\Users\appveyor\AppData\Roaming\Pub\Cache\bin"

    # Run pub get.
    pub get

    # Verify that the libraries are error free.
    pub global activate tuneup
    pub global run tuneup check --ignore-infos
    throw_if_process_failed "libraries have errors"

    # Run the tests.
    dart test\all.dart
    throw_if_process_failed "tests failed"

    # Verify that the generated grind script analyzes well.
    dart tool\grind.dart analyze-init
    throw_if_process_failed "error analyzing generated script"
}

switch ($action) {
    "install" { install }
    "test" { test }
}
