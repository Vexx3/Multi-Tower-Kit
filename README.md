# Multi Tower Kit

A comprehensive kit for creating EToH (Eternal Towers of Hell) fangames on Roblox with minimal effort. Simply configure a few settings and you're ready to go!

## Features

- 🗼 **Easy Tower Setup** — Add towers with automatic checkpoint detection and win tracking
- ⏱️ **Timer System** — Built-in synchronized timer with anti-cheat checkpoint verification
- 🎨 **Customizable Difficulties** — Pre-configured difficulty system (Easy to Catastrophic) with colors and Discord emoji support
- 📊 **Data Persistence** — Automatic player data saving (tower completions, stats, etc.)
- 🔔 **Webhook Integration** — Discord webhook support for tower completion announcements
- 🛡️ **Admin System** — Role-based permission system with configurable admin commands
- 🎮 **Tower Rushes** — Support for multi-tower rush sequences
- ✨ **Animated Winpads** — Color-cycling winpads with customizable effects

## Usage

### Getting Started

1. **Build the project** using [Rojo](https://rojo.space/docs):
   ```bash
   rojo build -o "Multi Tower Kit.rbxlx"
   ```

2. **Open** `Multi Tower Kit.rbxlx` in Roblox Studio

3. **Start the Rojo server** for live syncing:
   ```bash
   rojo serve
   ```

### Configuration

All main configuration is done in `src/ReplicatedStorage/GameData/`:

#### Config.luau
The main configuration file where you can customize:
- Timer sync intervals
- Restart cooldowns
- Winpad appearance settings
- Data store keys
- Webhook messages
- Admin roles and permissions

#### Difficulties.luau
Define your tower difficulties with:
- Title and rating
- Display color
- Discord emoji for webhooks
- Global announcement settings

#### Badges.luau
Configure badges awarded for tower completions.

### Adding Towers

1. Create your tower in Workspace
2. Add checkpoints to `ServerStorage/TowerCheckpoints`
3. Configure tower data in `ReplicatedStorage/RealmData/RealmInfo.luau`

### Admin Commands

Press `F4` (configurable) to open the admin console. Permissions are role-based and configured in `Config.luau`.

## Project Structure

```
src/
├── ReplicatedStorage/    # Shared game data and configuration
│   ├── GameData/         # Config, Difficulties, Badges
│   ├── RealmData/        # Tower and realm definitions
│   └── Shared/           # Utility modules and types
├── ServerScriptService/  # Server-side scripts
│   └── Server/           # Core server logic, commands, logging
├── ServerStorage/        # Server assets (checkpoints, GUI templates)
└── StarterPlayerScripts/ # Client-side scripts and modules
```

## Dependencies

This project uses [Wally](https://wally.run/) for package management. Install dependencies with:
```bash
wally install
```

## License

Licensed under the MIT License.

Original Copyright (c) 2023 fanofpixels  
Modifications Copyright (c) 2025 Zylx