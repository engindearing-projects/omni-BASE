/**
 * CotParser - Cursor on Target Message Parsing and Serialization
 *
 * Handles CoT XML parsing/generation following the CoT 2.0 specification.
 * Supports all standard detail elements used by ATAK, WinTAK, and iTAK.
 */

export interface CotEvent {
  version: string; // Usually "2.0"
  uid: string; // Unique identifier
  type: string; // CoT type code (e.g., "a-f-G-E-S" for friendly ground equipment)
  time: Date; // Time event was generated
  start: Date; // Time event becomes valid
  stale: Date; // Time event becomes stale
  how: string; // How the event was generated (e.g., "h-g-i-g-o" for GPS)
  point: CotPoint;
  detail?: CotDetail;
}

export interface CotPoint {
  lat: number; // Latitude in degrees
  lon: number; // Longitude in degrees
  hae: number; // Height above ellipsoid in meters
  ce: number; // Circular error in meters (horizontal accuracy)
  le: number; // Linear error in meters (vertical accuracy)
}

export interface CotDetail {
  contact?: CotContact;
  group?: CotGroup;
  precisionLocation?: CotPrecisionLocation;
  status?: CotStatus;
  track?: CotTrack;
  link?: CotLink[];
  remarks?: string;
  [key: string]: any; // Allow custom detail elements
}

export interface CotContact {
  callsign: string;
  endpoint?: string; // IP:port for direct connection
}

export interface CotGroup {
  name: string; // Team/group name
  role: string; // Role in team
}

export interface CotPrecisionLocation {
  geopointsrc: string; // GPS, USER, etc.
  altsrc: string; // GPS, DTED, etc.
}

export interface CotStatus {
  battery: number; // Battery percentage 0-100
}

export interface CotTrack {
  speed: number; // Speed in m/s
  course: number; // Heading in degrees
}

export interface CotLink {
  uid: string; // UID of linked event
  relation: string; // Relationship type (e.g., "p-p" for parent)
  type: string; // CoT type of linked event
}

/**
 * MIL-STD-2525 Affiliation Codes
 */
export enum Affiliation {
  Pending = 'p', // Unknown/Pending
  Unknown = 'u', // Unknown
  AssumedFriend = 'a', // Assumed Friend
  Friend = 'f', // Friend
  Neutral = 'n', // Neutral
  Suspect = 's', // Suspect
  Hostile = 'h', // Hostile
  Joker = 'j', // Exercise Assumed Friend
  Faker = 'k', // Exercise Friend
  None = 'o', // None specified
}

/**
 * Parse CoT XML string into structured object
 */
export function parseCotXml(xml: string): CotEvent | null {
  try {
    // Simple XML parsing - in production, use proper XML parser
    // For now, extract key fields with regex (to be replaced with real parser)

    const getAttr = (tag: string, attr: string): string | null => {
      const regex = new RegExp(
        `<${tag}[^>]*${attr}=["']([^"']*)["']`,
        'i'
      );
      const match = xml.match(regex);
      return match ? match[1] : null;
    };

    const uid = getAttr('event', 'uid');
    const type = getAttr('event', 'type');
    const time = getAttr('event', 'time');
    const start = getAttr('event', 'start');
    const stale = getAttr('event', 'stale');
    const how = getAttr('event', 'how');
    const lat = getAttr('point', 'lat');
    const lon = getAttr('point', 'lon');
    const hae = getAttr('point', 'hae');

    if (!uid || !type || !time || !start || !stale || !lat || !lon) {
      console.error('Missing required CoT fields');
      return null;
    }

    return {
      version: getAttr('event', 'version') || '2.0',
      uid,
      type,
      time: new Date(time),
      start: new Date(start),
      stale: new Date(stale),
      how: how || '',
      point: {
        lat: parseFloat(lat),
        lon: parseFloat(lon),
        hae: parseFloat(hae || '0'),
        ce: parseFloat(getAttr('point', 'ce') || '9999999'),
        le: parseFloat(getAttr('point', 'le') || '9999999'),
      },
      detail: parseDetail(xml),
    };
  } catch (error) {
    console.error('Failed to parse CoT XML:', error);
    return null;
  }
}

/**
 * Parse detail section of CoT message
 */
function parseDetail(xml: string): CotDetail | undefined {
  const detailMatch = xml.match(/<detail>(.*?)<\/detail>/s);
  if (!detailMatch) return undefined;

  const detailXml = detailMatch[1];
  const detail: CotDetail = {};

  // Parse contact
  const callsignMatch = detailXml.match(/<contact[^>]*callsign=["']([^"']*)["']/);
  if (callsignMatch) {
    detail.contact = { callsign: callsignMatch[1] };
  }

  // Parse group
  const groupMatch = detailXml.match(
    /<__group[^>]*name=["']([^"']*)["'][^>]*role=["']([^"']*)["']/
  );
  if (groupMatch) {
    detail.group = { name: groupMatch[1], role: groupMatch[2] };
  }

  // Parse remarks
  const remarksMatch = detailXml.match(/<remarks>([^<]*)<\/remarks>/);
  if (remarksMatch) {
    detail.remarks = remarksMatch[1];
  }

  return detail;
}

/**
 * Serialize CoT event to XML string
 */
export function serializeCotXml(event: CotEvent): string {
  const { version, uid, type, time, start, stale, how, point, detail } = event;

  let xml = `<?xml version="1.0" encoding="UTF-8"?>
<event version="${version}" uid="${uid}" type="${type}" time="${time.toISOString()}" start="${start.toISOString()}" stale="${stale.toISOString()}" how="${how}">
  <point lat="${point.lat}" lon="${point.lon}" hae="${point.hae}" ce="${point.ce}" le="${point.le}"/>`;

  if (detail) {
    xml += '\n  <detail>';

    if (detail.contact) {
      xml += `\n    <contact callsign="${detail.contact.callsign}"`;
      if (detail.contact.endpoint) {
        xml += ` endpoint="${detail.contact.endpoint}"`;
      }
      xml += '/>';
    }

    if (detail.group) {
      xml += `\n    <__group name="${detail.group.name}" role="${detail.group.role}"/>`;
    }

    if (detail.precisionLocation) {
      xml += `\n    <precisionlocation geopointsrc="${detail.precisionLocation.geopointsrc}" altsrc="${detail.precisionLocation.altsrc}"/>`;
    }

    if (detail.status) {
      xml += `\n    <status battery="${detail.status.battery}"/>`;
    }

    if (detail.track) {
      xml += `\n    <track speed="${detail.track.speed}" course="${detail.track.course}"/>`;
    }

    if (detail.link) {
      detail.link.forEach((link) => {
        xml += `\n    <link uid="${link.uid}" relation="${link.relation}" type="${link.type}"/>`;
      });
    }

    if (detail.remarks) {
      xml += `\n    <remarks>${detail.remarks}</remarks>`;
    }

    xml += '\n  </detail>';
  }

  xml += '\n</event>';
  return xml;
}

/**
 * Extract affiliation from CoT type code
 * CoT type format: [dimension]-[affiliation]-[category]...
 * Example: "a-f-G-E-S" = air-friend-ground equipment-sensor
 */
export function getAffiliation(cotType: string): Affiliation {
  const parts = cotType.split('-');
  if (parts.length < 2) return Affiliation.Unknown;

  const affiliationCode = parts[1].toLowerCase();
  switch (affiliationCode) {
    case 'p':
      return Affiliation.Pending;
    case 'u':
      return Affiliation.Unknown;
    case 'a':
      return Affiliation.AssumedFriend;
    case 'f':
      return Affiliation.Friend;
    case 'n':
      return Affiliation.Neutral;
    case 's':
      return Affiliation.Suspect;
    case 'h':
      return Affiliation.Hostile;
    case 'j':
      return Affiliation.Joker;
    case 'k':
      return Affiliation.Faker;
    default:
      return Affiliation.None;
  }
}

/**
 * Get display color for affiliation
 */
export function getAffiliationColor(affiliation: Affiliation): string {
  switch (affiliation) {
    case Affiliation.Friend:
    case Affiliation.AssumedFriend:
      return '#0000FF'; // Blue
    case Affiliation.Hostile:
      return '#FF0000'; // Red
    case Affiliation.Neutral:
      return '#00FF00'; // Green
    case Affiliation.Unknown:
    case Affiliation.Pending:
      return '#FFFF00'; // Yellow
    case Affiliation.Suspect:
      return '#FF00FF'; // Magenta
    default:
      return '#FFFFFF'; // White
  }
}

/**
 * Create a self-SA CoT event (position report)
 */
export function createSelfSACot(
  uid: string,
  callsign: string,
  lat: number,
  lon: number,
  hae: number = 0
): CotEvent {
  const now = new Date();
  const stale = new Date(now.getTime() + 60000); // Stale in 1 minute

  return {
    version: '2.0',
    uid,
    type: 'a-f-G-E-S', // Friendly ground equipment sensor
    time: now,
    start: now,
    stale,
    how: 'h-g-i-g-o', // GPS
    point: {
      lat,
      lon,
      hae,
      ce: 10.0, // 10m circular error
      le: 10.0, // 10m linear error
    },
    detail: {
      contact: {
        callsign,
      },
      precisionLocation: {
        geopointsrc: 'GPS',
        altsrc: 'GPS',
      },
    },
  };
}
