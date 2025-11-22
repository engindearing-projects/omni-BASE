import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

interface ChangelogEntry {
  version: string;
  date: string;
  changes: string[];
}

export async function GET() {
  try {
    const changelogPath = path.join(process.cwd(), '..', 'CHANGELOG.md');
    const content = fs.readFileSync(changelogPath, 'utf-8');

    const entries: ChangelogEntry[] = [];
    const lines = content.split('\n');
    let currentEntry: ChangelogEntry | null = null;

    for (const line of lines) {
      // Match version headers like "## [1.0.0] - 2024-01-15"
      const versionMatch = line.match(/^##\s+\[?([^\]]+)\]?\s*-\s*(.+)$/);
      if (versionMatch) {
        if (currentEntry) {
          entries.push(currentEntry);
        }
        currentEntry = {
          version: versionMatch[1],
          date: versionMatch[2],
          changes: [],
        };
      } else if (currentEntry && line.trim().startsWith('-')) {
        // Match bullet points
        const change = line.trim().replace(/^-\s*/, '');
        if (change) {
          currentEntry.changes.push(change);
        }
      }
    }

    if (currentEntry) {
      entries.push(currentEntry);
    }

    return NextResponse.json(entries);
  } catch (error) {
    console.error('Error reading changelog:', error);
    return NextResponse.json(
      [
        {
          version: '1.0.0',
          date: '2024-01-15',
          changes: ['Initial release with ATAK compatibility', 'iOS support', 'Team communication features'],
        },
      ]
    );
  }
}
