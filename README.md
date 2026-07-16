# Meeting AI

Automatic task extraction from meeting recordings using local AI.

## Quick Start

### 1. Install (one time)

1. Right-click `install.bat` → **Run as administrator**
2. Press any key when prompted
3. Wait 5-15 minutes (downloads 4.7 GB AI model)
4. When you see `INSTALLATION COMPLETE!`, close the window

### 2. Run

Double-click `run.bat`

## Requirements

- Windows 10/11
- 8 GB RAM minimum
- 15 GB free disk space
- Internet (first time only)

## How it works

1. Select an audio file (mp3, wav, m4a, etc.) or paste meeting transcript
2. Click "Start Processing"
3. Get tasks with assignees, deadlines and priorities
4. Export to CSV (Excel), JSON, or Markdown (Notion)

## Privacy

All processing happens locally on your computer. Nothing is sent to the internet after installation.

## Troubleshooting

**"Python not found"**
- Install Python from python.org
- Check "Add Python to PATH" during installation
- Restart and run install.bat again

**"Not installed" when running run.bat**
- Run install.bat as Administrator first

**Slow performance**
- Close other applications during processing
- For weak PCs: edit install.bat, change `qwen2.5:7b` to `qwen2.5:3b`

## License

MIT
