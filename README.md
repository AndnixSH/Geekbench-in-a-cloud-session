# Geekbench in a cloud session

Runs the [Geekbench](https://www.geekbench.com/) CPU benchmark inside a
Claude Code cloud session (or any Linux box) and prints the Geekbench Browser
links for the result.

```sh
./run-geekbench.sh
```

The script downloads Geekbench from `cdn.geekbench.com` into `.geekbench/`,
runs `geekbench7 --cpu`, and prints the scores, the result URL, and the claim
URL that adds the result to your Geekbench account.

| Variable     | Default         | Meaning                                         |
|--------------|-----------------|-------------------------------------------------|
| `GB_VERSION` | `7.1.0`         | Geekbench version to download                   |
| `GB_WORKDIR` | `./.geekbench`  | Where the download, logs and traces go          |
| `GB_TRACE`   | `0`             | `1` logs the hosts Geekbench connects to (needs `strace`) |

The free edition of Geekbench always uploads results, so the machine needs
internet access. Logs in `.geekbench/` contain the claim key, which lets
anyone add the result to their account; they are git-ignored.

## Notes

- `browser.geekbench.com` and `www.geekbench.com` sit behind a Cloudflare bot
  check that blocks cloud-session IPs, so you can't view results from inside
  the session. Open the links in your own browser. The CDN and the upload
  itself aren't blocked.
- Only the CPU benchmark runs; the session has no GPU.
