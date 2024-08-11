#!/bin/bash
set -euo pipefail

# Update
git submodule update --remote --merge

# VRF
cd ValveResourceFormat
dotnet clean --configuration Release Decompiler/Decompiler.csproj
dotnet publish --configuration Release -p:PublishSingleFile=true --runtime linux-x64 --self-contained Decompiler/Decompiler.csproj

# ProtobufDumper
cd ../SteamKit
dotnet clean --configuration Release Resources/ProtobufDumper/ProtobufDumper/ProtobufDumper.csproj
dotnet publish --configuration Release -p:PublishSingleFile=true --runtime linux-x64 --self-contained Resources/ProtobufDumper/ProtobufDumper/ProtobufDumper.csproj

# Strings
cd ../DumpStrings
go build
