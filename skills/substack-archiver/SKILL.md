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
pip install feedparser bs4 requests html2text
```

### Download All Posts (v3 - free posts only)

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

## Method 3: API-Based Archive Download (with subscription)

**Use this method to download the full archive (hundreds of posts).**

### Installation

```bash
cd /home/jrs/substack-downloader
pip install requests html2text
```

### Authentication (with your Substack session cookie)

You need your Substack session cookie (`substack.sid`). Copy it from:
1. Open Substack in Firefox on Mac
2. Developer Tools → Application → Cookies → `substack.sid`
3. Set as environment variable: `export SUBSTACK_SID="YOUR_COOKIE_VALUE"`

Or paste your cookie directly:
```bash
export SUBSTACK_SID="s%3AcMmFhrK-fExuCj1SLumQ-RVZD_8mi2lq.gHPf%2FvrOuO6Rp65fFdH1cw2iOnvqs5%2FqSHUHjNC%2FNc8"
```

### Download All Posts (v5 - full archive with API)

```bash
export SUBSTACK_SID="s%3AcMmFhrK-fExuCj1SLumQ-RVZD_8mi2lq.gHPf%2FvrOuO6Rp65fFdH1cw2iOnvqs5%2FqSHUHjNC%2FNc8"
cd /home/jrs/substack-downloader
python download_kaitchup_v5.py
```

This uses Substack's undocumented JSON API with pagination:
- `GET /api/v1/archive?offset=N&limit=50` - fetch archive batches
- `GET /api/v1/posts/by-id/{post_id}` - fetch full post content
- Automatically paginates through all posts (~459 posts in The Kaitchup)
- Saves posts with section prefixes (archive_2026-08-02_filename.md)

### Why v5 is Better Than v4
- **v4**: Full archive with API → 459 posts
- **v5**: Enhanced v4 with better file organization → same 459 posts
- Improved progress tracking and error handling
- Better filename naming with section prefixes
- More robust deduplication

### API-Based Download Strategy

| Method | Posts | Auth Required | Notes |
|--------|-------|---------------|-------|
| RSS + Archive (v3) | 29 | No | Free posts only |
| API with Cookie (v4) | 459 | Yes | Full archive with paid content |

For full archive access (hundreds of posts), you need:
- Substack paid subscription (to get session cookie)
- Browser automation with session cookies transferred from Mac to DGX Spark
- Or wait for Substack to add pagination to their public API

## Usage

### The Kaitchup - Full Archive (API Method - RECOMMENDED)

This is the recommended method for downloading the complete archive:

```bash
cd /home/jrs/substack-downloader
export SUBSTACK_SID="s%3AcMmFhrK-fExuCj1SLumQ-RVZD_8mi2lq.gHPf%2FvrOuO6Rp65fFdH1cw2iOnvqs5%2FqSHUHjNC%2FNc8"
python download_kaitchup_v5.py
```

This downloads **459 posts** using Substack's API with pagination.

### The Kaitchup - Free Posts Only (v3 Method)

If you don't have a Substack subscription, use the v3 script:

```bash
cd /home/jrs/substack-downloader
python download_kaitchup_v3.py
```

This downloads ~29 free posts from RSS + archive page.

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

✅ **459 posts downloaded successfully (v4 - full archive with API):**

### v4 (new - API-based with pagination):
- Downloads **459 posts total** using Substack's undocumented JSON API
- Automatically paginates through all archive batches
- Downloads full post content in Markdown format
- Uses session cookie for authenticated access to paid content
- Skips already-downloaded posts automatically

### v3 (free posts only):
- Downloads **29 posts** from RSS + archive page
- No authentication required
- Limited to publicly available content

### v2 (archive only - legacy):
- Downloads **12 posts** from static HTML
- Superseded by v3 which aggregates from multiple sources

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

### Missing posts (v3 - RSS/Archive)
- Try `--limit 100` to force more posts
- Check if some posts are behind a paywall (requires valid session)

### Missing posts (v4 - API)
- API returns 459 posts total for The Kaitchup
- Some posts may fail if they're behind a paywall without valid auth
- The script automatically skips already-downloaded posts
- If many posts fail, check your SUBSTACK_SID cookie is valid

### 429 Too Many Requests error
- Reduce the `limit` parameter in the script
- Add longer delays between requests
- The script uses 1 second delay by default

### 404 Not Found error
- The post may have been deleted or moved
- Check the post ID in the archive
- The script will skip these and continue

### Deduplication not working (v3)
- Use v3 which aggregates from multiple sources and deduplicates
- Check for existing files before downloading (v3 handles this automatically)

### Deduplication not working (v4)
- v4 uses post IDs from API to check if already downloaded
- Post ID is saved in each markdown file header
- The script skips posts that were already downloaded
- If many posts fail, check your SUBSTACK_SID cookie is valid

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