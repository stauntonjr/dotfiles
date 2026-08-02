---
name: substack-archiver
description: Download and archive Substack newsletters you're subscribed to
version: 2
created: 2026-08-02
updated: 2026-08-02
---
## When to Use
Use this skill when you need to download and archive all posts from a Substack newsletter you're subscribed to (like The Kaitchup).

## Method 1: Use substack-downloader (for paid/subscriber content)

**GitHub:** https://github.com/carlvellotti/substack-downloader

**Key Features:**
- Downloads all posts from newsletters you're subscribed to
- Converts to Markdown (perfect for Obsidian/Notion)
- Downloads images locally
- Supports paid/subscriber-only content
- 100% local (your cookies stay on your machine)

### Installation

```bash
cd /home/jrs/substack-downloader
pip install -r requirements.txt
playwright install chromium
```

### Authentication (on Mac with GUI)

**Important:** You need to log in with your Substack credentials (your Gmail account).

#### Standard Substacks (e.g. kaitchup.substack.com)
```bash
cd /home/jrs/substack-downloader
python login.py
```

A Chrome window will open. Log in to `substack.com` with your Gmail account (jack.rory.staunton@gmail.com). Press Enter in the terminal when done.

### Custom Domain Substacks
If the newsletter has a custom domain, specify the URL:
```bash
python login.py https://www.customdomain.com
```

This creates `substack_session.json` which works for all standard Substack newsletters.

## Method 2: Direct Archive Download (free for public posts)

If you don't need paid content, use the direct archive download script.

### Installation (for The Kaitchup)

```bash
cd /home/jrs/substack-downloader
pip install feedparser bs4 requests
```

### Download All Posts

```bash
python download_kaitchup_v3.py
```

This downloads all posts from multiple sources:
- RSS feed (20 posts)
- Archive page (12 posts)
- Tutorials section (12 posts)
- Notebooks section (0 posts)
- **Total: 29 unique posts** (with deduplication)

### Why v3 is Better Than v2
- **v2**: Only scraped the archive page → 12 posts
- **v3**: Aggregates from RSS, archive, tutorials, and notebooks → 29 posts
- Automatically deduplicates across all sources

### Download Strategy for Public Posts Only

| Source | Posts | Notes |
|--------|-------|-------|
| RSS Feed | 20 | Always returns latest 20 posts, no pagination |
| Archive Page (static) | ~12 | Only first page visible, infinite scroll requires automation |
| Tutorials Section | ~12 | Same limitation as archive page |
| Notebooks Section | 0 | May be empty or same as archive |

**Total publicly accessible**: ~20-32 posts without subscription

#### Why Full Archive Is Limited

1. **No API Pagination**: `/api/v1/archive` returns ~100 posts but no offset parameter for fetching more
2. **RSS Limitation**: Standard RSS behavior - Substack only exposes latest 20 posts
3. **Infinite Scroll**: Archive page loads dynamically via JavaScript; static HTML parsing only sees initial view
4. **Paid Content**: Hidden posts (`hidden: true`, `audience: only_paid`) require authentication

#### Optimal Strategy

```python
# Best approach without subscription:
1. RSS feed → 20 posts (all publicly available)
2. Archive page → ~12 additional posts (visible in static HTML)
3. Deduplicate → ~22-29 unique posts
```

For full archive access (hundreds of posts), you need:
- Substack paid subscription
- Browser automation with session cookies (requires GUI login on Mac, then transfer `substack_session.json` to DGX Spark)
- Or wait for Substack to add pagination to their public API

## Usage

### The Kaitchup - All Posts (Direct Method)
```bash
cd /home/jrs/substack-downloader
python download_kaitchup_v3.py
```

### substack-downloader (with authentication)
```bash
python scraper.py --url https://kaitchup.substack.com
```

### Markdown Only (Best for Mining Ideas)
```bash
python scraper.py --url https://kaitchup.substack.com --md-only
```

### Limit Number of Posts (Test Run)
```bash
python scraper.py --url https://kaitchup.substack.com --limit 10
```

### Skip Podcasts
```bash
python scraper.py --url https://kaitchup.substack.com --skip-podcasts
```

## Output

Downloads saved to `archive/kaitchup.substack.com/`:

```
archive/
└── kaitchup.substack.com/
    ├── 2026-08-02_4-bit-glm47-with-a-single-b300-high.md
    ├── 2026-08-02_agentic-ai-at-two-different-scales.md
    ├── 2026-08-02_bonsai-27b-review-can-a-39-gb-1-bit.md
    └── ...
```

## Post-Download Mining

### Extract All Headings
```bash
cd /home/jrs/substack-downloader/archive/kaitchup.substack.com
grep -h "^## " *.md | sort -u
```

### Extract All Code Blocks
```bash
grep -rh "^```" *.md
```

### Find Posts About Specific Topics
```bash
grep -l "DGX Spark" *.md
grep -l "sparkrun" *.md
grep -l "Qwen" *.md
```

### Create a Topic Index
```bash
for f in *.md; do
  title=$(head -1 "$f")
  topics=$(grep -o "#[a-zA-Z]*" "$f" | sort -u | tr '\n' ', ')
  echo "$title | Topics: $topics"
done
```

### Count Total Posts
```bash
ls -1 *.md | wc -l
```

## The Kaitchup Archive Status

✅ **29 posts downloaded successfully (v3 - comprehensive method):**

### New Posts in v3 (not in v2):
1. `4-bit-GLM4.7-with-a-single-B300-high` - 4-bit quantization on B300
2. `dflash-vs-mtp-qwen36-speculative` - DFlash vs MTP speculative decoding
3. `eagle-3-speculators-when-to-use-them` - Eagle-3 speculator models
4. `glm-5-memory-requirements-explained` - GLM-5 memory requirements
5. `how-to-deploy-your-llm-in-the-cloud` - Cloud deployment guide
6. `how-to-reduce-llm-inference-cost` - Cost optimization techniques
7. `make-your-own-optimized-ggufs-with` - GGUF optimization tutorial
8. `moq-ggufs-and-gsq-low-bit-ggufs-are` - MOQ and GSQ quantization
9. `new-diffusiongemma-and-moq-ggufs` - DiffusionGemma and MOQ
10. `qwen35-9b-moq-inside-a-strong-36` - Qwen3.5 9B MOQ analysis
11. `qwen35-quantization-similar-accuracy` - Qwen3.5 quantization
12. `qwopus-and-reap-custom-qwen36-models` - QwOpus and REAP custom models
13. `reasoning-budgets-vs-structured-cot` - Reasoning budget comparison
14. `serving-exllamav3-with-tabbyapi-accuracy` - ExLlama v3 deployment
15. `the-kv-cache-of-small-moes-qwen3` - KV cache for small MoEs
16. `train-and-run-dflash-speculative` - DFlash training and inference

### From v2 (already downloaded):
1. `agentic-ai-at-two-different-scales` - Agentic AI at two scales
2. `bonsai-27b-review-can-a-39-gb-1-bit` - Bonsai 27B review
3. `deepseek-v4-flash-0731-and-inkling` - DeepSeek V4 Flash vs Pro
4. `dspark-and-nvidias-qwen36-nvfp4-models` - DSpark and NVFP4 models
5. `efficient-and-reasoning-ai-at-the` - ACL 2026 papers
6. `glm-52-only-a-few-months-behind-commercial` - GLM-5.2 status
7. `inkling-gemma-4-updates-and-1-bit` - Inkling and Gemma 4
8. `lfm25-230m-and-350m-how-accurate` - LFM2.5 GGUF accuracy
9. `minimax-m3-gguf-quantization-from` - Minimax M3 quantization
10. `qwen36-27b-kv-cache-quantization` - Qwen3.6 KV cache
11. `qwen38-what-hardware-will-you-need` - Qwen3.8 hardware
12. `this-week-in-open-models-tiny-lfm25` - Weekly open models

## Troubleshooting

### Download Limitations and Strategy

#### What's Available Without Subscription

| Source | Posts | Notes |
|--------|-------|-------|
| RSS Feed | 20 | Always returns latest 20 posts, no pagination |
| Archive Page (static) | ~12 | Only first page visible, infinite scroll requires automation |
| Tutorials Section | ~12 | Same limitation as archive page |
| Notebooks Section | 0 | May be empty or same as archive |

**Total publicly accessible**: ~20-32 posts without subscription

#### Why Full Archive Is Limited

1. **No API Pagination**: `/api/v1/archive` returns ~100 posts but no offset parameter for fetching more
2. **RSS Limitation**: Standard RSS behavior - Substack only exposes latest 20 posts
3. **Infinite Scroll**: Archive page loads dynamically via JavaScript; static HTML parsing only sees initial view
4. **Paid Content**: Hidden posts (`hidden: true`, `audience: only_paid`) require authentication

#### Optimal Strategy

```python
# Best approach without subscription:
1. RSS feed → 20 posts (all publicly available)
2. Archive page → ~12 additional posts (visible in static HTML)
3. Deduplicate → ~22-29 unique posts
```

For full archive access (hundreds of posts), you need:
- Substack paid subscription
- Browser automation with session cookies (requires GUI login on Mac, then transfer `substack_session.json` to DGX Spark)
- Or wait for Substack to add pagination to their public API

### "Login required" error (substack-downloader)
- Run `python login.py` again
- Make sure you're logged into the correct Gmail account
- Check `substack_session.json` exists

### "403 Forbidden" error
- The newsletter may have bot protection enabled
- Try with custom domain: `python login.py https://kaitchup.substack.com`

### Missing posts
- Try `--limit 100` to force more posts
- Check if some posts are behind a paywall (requires valid session)

### Deduplication not working
- Use v3 which aggregates from multiple sources and deduplicates
- Check for existing files before downloading (v3 handles this automatically)

## Security Notes

- Your session file (`substack_session.json`) contains your authentication
- Keep it private and never share it
- It expires when you log out or change your password
- All downloads stay local on your machine

## Advanced: Download from Specific Date Range

To download posts from a specific time period:

```python
# Add to download_kaitchup_v3.py
from datetime import datetime

def filter_by_date(posts, start_date, end_date):
    """Filter posts by publication date"""
    # Requires parsing dates from post metadata
    # Returns filtered list
    pass
```

## Future Improvements

- [ ] Add date range filtering
- [ ] Extract and index topics/keywords
- [ ] Generate table of contents with post summaries
- [ ] Download images to local directory
- [ ] Create PDF archives
- [ ] Add incremental updates (check for new posts since last run)