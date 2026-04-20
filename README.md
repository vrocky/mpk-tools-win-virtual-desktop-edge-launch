# Edge Profile Picker

A lightweight WPF desktop application for Windows that lists all Microsoft Edge browser profiles and launches a chosen profile in a new Edge window. It is designed as a fast, keyboard-friendly alternative to navigating Edge's built-in profile switcher.

---

## Features

- Automatically discovers every Edge profile on the machine by reading the `%LOCALAPPDATA%\Microsoft\Edge\User Data` directory
- Displays each profile as a card showing:
  - A circular avatar — either the profile's `Edge Profile.ico` image or generated initials on a colour background
  - Display name (read from the profile's `Preferences` JSON file)
  - Signed-in account email, or "No account signed in" when no account is linked
  - The profile's folder identifier badge (`Default`, `Profile 1`, `Profile 2`, …)
- Live search bar that filters cards by name, email, or folder name (case-insensitive)
- Clicking a card launches `msedge.exe --profile-directory="<folder>" --new-window about:blank` and then shuts down the picker — so the picker never stays running in the background
- Dark UI using a navy/crimson colour theme (`#1a1a2e` background, `#e94560` accent)
- Resizable window (minimum 400 × 400) with a thin custom scrollbar
- Ships with a PowerShell script to create a desktop shortcut

---

## Project Structure

```
edge-profile-picker/
├── EdgeProfilePicker.csproj          # SDK-style project: net8.0-windows, WPF enabled
├── AssemblyInfo.cs                   # Assembly metadata
├── App.xaml / App.xaml.cs           # WPF application entry point
├── MainWindow.xaml                   # UI layout, styles, and DataTemplates
├── MainWindow.xaml.cs               # Code-behind: load, search, launch logic
├── Models/
│   └── EdgeProfile.cs               # Data model for a single Edge profile
├── Services/
│   └── EdgeProfileService.cs        # Reads Edge profile directories and Preferences JSON
├── Converters/
│   └── StringToColorBrushConverter.cs  # IValueConverter: hex string → SolidColorBrush
├── app.ico                           # Application/window icon (Edge icon)
├── CreateShortcut.ps1               # PowerShell: creates Desktop shortcut to the exe
└── docs/
    └── architecture.md              # Detailed architecture and data-flow documentation
```

---

## Requirements

- Windows 10 or Windows 11
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) (for build/run)
- .NET 8 Desktop Runtime (for running the published executable)
- Microsoft Edge installed at the default path:
  `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe`

---

## How to Build

From the repository root in any terminal:

```powershell
dotnet build
```

The debug binary is written to:

```
bin\Debug\net8.0-windows\EdgeProfilePicker.exe
```

---

## How to Run

```powershell
dotnet run
```

Or launch the compiled executable directly:

```powershell
.\bin\Debug\net8.0-windows\EdgeProfilePicker.exe
```

The application window opens centred on screen, immediately loads and displays all discovered Edge profiles, and focuses the search box.

---

## How to Publish (Self-Contained Single File)

To produce a standalone executable that does not require a separately installed .NET runtime:

```powershell
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true
```

The output is placed in:

```
bin\Release\net8.0-windows\win-x64\publish\EdgeProfilePicker.exe
```

For a framework-dependent build (smaller, requires .NET 8 Desktop Runtime installed):

```powershell
dotnet publish -c Release
```

---

## How It Works

### Profile Discovery

`EdgeProfileService.LoadProfiles()` performs the following steps:

1. Resolves `%LOCALAPPDATA%\Microsoft\Edge\User Data` using `Environment.SpecialFolder.LocalApplicationData` — no paths are hardcoded.
2. Enumerates subdirectories, keeping only `Default` and folders matching the pattern `Profile N` (where N is a valid integer).
3. Orders the list: `Default` first, then numeric order.
4. For each qualifying folder, reads the `Preferences` file (plain UTF-8 JSON) using `System.Text.Json.JsonDocument`.
5. Extracts `profile.name` (display name) and `profile.user_name` (signed-in email).
6. Looks for `Edge Profile.ico` in the profile folder; sets `PicturePath` to the full path if found, otherwise leaves it `null`.
7. Assigns initials (up to two capital letters from the display name) and cycles through a palette of eight accent colours.

### UI Binding

`MainWindow` assigns the profile list to an `ItemsControl`. Each item is rendered by a `DataTemplate` containing a `Button` whose `Tag` is set to the profile's `Folder` string. The `StringToColorBrushConverter` converts the `AvatarColor` hex string to a WPF `SolidColorBrush` inline during binding.

### Profile Launch

When a card button is clicked, `ProfileCard_Click` reads the folder name from `Button.Tag` and calls:

```csharp
Process.Start(new ProcessStartInfo
{
    FileName = EdgeProfileService.EdgeExePath,
    Arguments = $"--profile-directory=\"{folder}\" --new-window about:blank",
    UseShellExecute = false
});
Application.Current.Shutdown();
```

The picker shuts itself down immediately after starting Edge.

---

## Creating a Desktop Shortcut

Run the included PowerShell script once after building:

```powershell
powershell -ExecutionPolicy Bypass -File CreateShortcut.ps1
```

This creates `Edge Profile Picker.lnk` on the current user's Desktop. The shortcut points to the Debug build and uses the Edge executable icon. Edit the script's `$sc.TargetPath` and `$sc.WorkingDirectory` to point at a Release or published binary if preferred.

---

## Colour Reference

| Role                  | Hex       |
|-----------------------|-----------|
| Window background     | `#1a1a2e` |
| Card background       | `#16213e` |
| Card hover background | `#1e2f5e` |
| Border / nav blue     | `#0f3460` |
| Accent / pressed red  | `#e94560` |
| Body text             | `#e0e0e0` |
| Muted text            | `#888888` |
| Folder badge bg       | `#0a1628` |

---

## Limitations

- The Edge executable path is hardcoded in `EdgeProfileService.EdgeExePath` to the default 32-bit installation location. Machines with a custom Edge install path require that constant to be updated.
- Guest profiles and the `System Profile` directory are intentionally excluded.
- Profile pictures that are stored as JPEG/PNG inside the profile folder (rather than as `Edge Profile.ico`) are not displayed; only the `.ico` file is checked.
