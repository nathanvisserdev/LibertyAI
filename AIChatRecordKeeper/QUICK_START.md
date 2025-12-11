# Quick Start Guide

## First-Time Setup

1. **Launch the App**
   - Open AI Chat Record Keeper
   - The app will create necessary directories automatically

2. **Configure iCloud (Optional)**
   - macOS will prompt for iCloud Drive access
   - Grant permission for automatic cloud backups

## Importing Your First Transcript

### Step 1: Get Your Chat Transcript
**From ChatGPT:**
- Open your conversation
- Click the three dots (⋯) menu
- Select "Share" → "Copy link" or export as text

**From Claude:**
- Use the export feature in Claude
- Copy the conversation text

**From Other Platforms:**
- Copy the entire conversation thread
- Include all messages and timestamps if possible

### Step 2: Import to the App
1. Click the **+ (Plus)** button in the toolbar
2. Fill in the form:
   - **Title**: Give your conversation a memorable name
   - **Source Platform**: Select ChatGPT, Claude, etc.
   - **Source URL**: Paste the original URL (optional but recommended)
   - **Content**: Paste or type the full conversation
   - **Export Format**: Choose Plain Text, Markdown, or PDF
3. Click **Import**

### Step 3: Automatic Processing
The app will automatically:
- ✓ Save the file to local storage
- ✓ Compute the SHA-256 hash
- ✓ Create the first chain of custody entry
- ✓ Display your transcript in the list

## Understanding the Hash

The **SHA-256 hash** is your transcript's unique "fingerprint":
```
Example: a3f7b8c9d2e1f4g5h6i7j8k9l0m1n2o3p4q5r6s7t8u9v0w1x2y3z4a5b6c7d8e9f0
```

**What it proves:**
- The file existed in this exact form
- Any change to the file (even one character) completely changes the hash
- Third parties can verify authenticity by recomputing the hash

## Publishing Your Hash (Critical Step!)

**Why publish?** A hash only proves tampering if you can prove *when* the file existed. Publishing creates an independent timestamp.

### Option 1: GitHub Gist (Recommended)
1. Get a GitHub Personal Access Token:
   - Go to https://github.com/settings/tokens/new
   - Name: "AI Chat Timestamps"
   - Scope: Select "gist"
   - Click "Generate token" and copy it
   
2. In the app:
   - Select your transcript
   - Click **"Publish Hash"**
   - Choose "GitHub Gist"
   - Paste your token
   - Click **"Publish"**
   
3. Result: Public, timestamped gist that anyone can verify

### Option 2: OpenTimestamps (Free, No Account)
1. Select your transcript
2. Click **"Publish Hash"**
3. Choose "OpenTimestamps"
4. Click **"Publish"**

Result: Your hash is submitted to the Bitcoin blockchain (free service)

### Option 3: Email Yourself
1. Click **"Publish Hash"**
2. Choose "Email"
3. Your mail client opens with pre-filled hash info
4. Send to yourself

Result: Email headers prove the timestamp

## Verifying Integrity

**To check if your transcript has been modified:**

1. Select the transcript
2. Click **"Verify Integrity"**
3. The app will:
   - Recompute the file's current hash
   - Compare to the stored hash
   - Display: ✓ Verified or ⚠ Modified

**Green ✓**: File is unchanged since import
**Red ⚠**: File has been altered (investigate!)

## Viewing Chain of Custody

The chain of custody is your complete audit trail:

1. Select a transcript
2. Click **"View Chain of Custody"**
3. See the timeline of all actions:
   - When imported
   - Hash computation
   - Publications
   - Backups
   - Verifications

4. Click **"Generate Report"** to export a text file

## Backup Strategies

### Automatic: iCloud Drive
- Enabled by default if you granted permission
- Syncs across your Macs
- Versioned (can recover old versions)

### Manual: External Drive
1. Select a transcript
2. Click **"Backup to..."**
3. Choose an external drive or USB
4. For write-once media (optical discs):
   - Burn to CD/DVD
   - Mark as "write-protected" or "finalized"

### Best Practice: 3-2-1 Rule
- **3** copies of your data
- **2** different storage types (local + cloud)
- **1** offsite backup (external drive stored elsewhere)

## Recommended Workflow

**For each important conversation:**

1. **Import** immediately after the chat
2. **Verify** the hash was computed correctly
3. **Publish** to at least one service (GitHub Gist or OpenTimestamps)
4. **Backup** to iCloud (automatic) and one external location
5. **Document** - the chain of custody updates automatically

**Periodic verification:**
- Monthly: Verify integrity of all transcripts
- Review chain of custody for anomalies
- Ensure backups are still accessible

## Proving Authenticity to Others

When you need to prove a transcript is authentic:

1. **Provide the transcript file**
2. **Share the published hash** (GitHub gist URL, blockchain transaction, etc.)
3. **Recipient verifies:**
   - Computes SHA-256 hash of the file you provided
   - Compares to the independently published hash
   - Checks the publication timestamp
   - If they match: Proves the file existed in that form at that time

**Example verification command (Terminal):**
```bash
shasum -a 256 transcript.txt
# Output: a3f7b8c9d2e1f4g5... (compare to published hash)
```

## Troubleshooting

### "iCloud Drive not available"
- Open System Settings → iCloud
- Enable "iCloud Drive"
- Grant access when prompted

### "Failed to publish to GitHub"
- Check your Personal Access Token
- Ensure "gist" scope is enabled
- Token may have expired - generate a new one

### "Verification failed - hash mismatch"
- **Critical**: The file has been modified
- Check chain of custody for when it changed
- Compare to your backups
- If all copies show mismatch, investigate who had access

### "Cannot find file"
- File may have been moved or deleted
- Check the storage location path
- Restore from backup if needed

## Advanced: Custom Webhooks

If you have your own server or want to integrate with other services:

1. Set up an HTTP endpoint that accepts POST requests
2. In the app, choose "Custom Webhook"
3. Enter your endpoint URL
4. The app will POST JSON:
```json
{
  "title": "Conversation Title",
  "hash": "a3f7b8c9d2e1...",
  "timestamp": "2025-12-11T10:30:00Z",
  "algorithm": "SHA-256"
}
```

## Security Best Practices

1. **Never edit** transcript files after import (breaks hash verification)
2. **Publish immediately** to establish timestamp proof
3. **Test your backups** periodically
4. **Guard your GitHub token** - it has write access to your gists
5. **Verify regularly** - catch tampering early
6. **Export chain of custody** with transcripts when sharing

## Getting Help

- **Check DEVELOPER_GUIDE.md** for technical details
- **Review README.md** for project overview
- **Inspect chain of custody** if something seems wrong

## What Success Looks Like

After following this guide, you should have:
- ✓ At least one transcript imported
- ✓ SHA-256 hash computed and stored
- ✓ Hash published to GitHub Gist or OpenTimestamps
- ✓ Backup in iCloud or external storage
- ✓ Chain of custody showing all actions
- ✓ Successful integrity verification

**You now have cryptographically verifiable, independently timestamped proof of your AI conversation!**
