# UI Layout Reference

## Screen Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [TAK] ↓15 ↑3  ±8m  12:30                                   │  ← Status Bar
├─────────────────────────────────────────────────────────────┤
│                                                               │
│                                                               │
│  [LAYERS]         MAP VIEW                    [FILTER PANEL] │
│  [Panel]          (MapKit)                    [or]           │
│  (Left)                                       [UNIT LIST]    │
│                                               (Right)        │
│                                                               │
│                                                               │
│                                                               │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│  [Layers][Filter][Units]  [GPS][Broadcast][+/-] [Tools]     │  ← Bottom Toolbar
└─────────────────────────────────────────────────────────────┘
```

## Filter Panel Layout (320pt wide)

```
┌────────────────────────────────────┐
│ [Filter Icon] FILTER UNITS (2) [X] │  ← Header
├────────────────────────────────────┤
│ [] Search callsign or UID...     │  ← Search Bar
├────────────────────────────────────┤
│ QUICK FILTERS                      │
│ ┌─────────┬─────────┐              │
│ │  All    │ Friendly│              │
│ ├─────────┼─────────┤              │
│ │ Hostile │ Nearby  │              │  ← Quick Filters (2x4)
│ ├─────────┼─────────┤              │
│ │ Recent  │ Ground  │              │
│ ├─────────┼─────────┤              │
│ │  Air    │         │              │
│ └─────────┴─────────┘              │
├────────────────────────────────────┤
│ 2 filter(s) active                 │  ← Active Indicator
├────────────────────────────────────┤
│ AFFILIATION                        │
│  Friendly                         │
│  Hostile                          │  ← Affiliation Toggles
│  Neutral                          │
│  Unknown                          │
│  Assumed Friend                   │
│  Suspect                          │
├────────────────────────────────────┤
│ CATEGORY                           │
│ ┌─────────┬─────────┐              │
│ │  Ground│  Air   │              │
│ ├─────────┼─────────┤              │  ← Category Toggles (2x4)
│ │  Naval │  Sub   │              │
│ ├─────────┼─────────┤              │
│ │  Instal│  Sensor│              │
│ ├─────────┼─────────┤              │
│ │  Equip │  Other │              │
│ └─────────┴─────────┘              │
├────────────────────────────────────┤
│ > ADVANCED FILTERS                 │  ← Expandable
│                                    │
│ [Toggle] Distance Range            │
│   Max: 5.0 km                      │  ← Slider
│   [────●──────────]                │
│                                    │
│ [Toggle] Age Range                 │
│   Max: 30m                         │  ← Slider
│   [──────●────────]                │
│                                    │
│ [Toggle] Show Stale Units (>15m)  │
├────────────────────────────────────┤
│ SORT BY                            │
│ [Distance ▼] [↑]                   │  ← Sort Picker + Direction
├────────────────────────────────────┤
│ STATISTICS                         │
│ Total Units:      47               │
│ Avg Distance:     2.3 km           │  ← Statistics
│ Avg Age:          12m              │
├────────────────────────────────────┤
│ [Reset All Filters]                │  ← Reset Button
└────────────────────────────────────┘
```

## Unit List Panel Layout (360pt wide)

```
┌────────────────────────────────────────┐
│ [List Icon] UNIT LIST (47) [X]         │  ← Header
├────────────────────────────────────────┤
│ ▼ FRIENDLY (32)                        │  ← Section Header
│ ┌────────────────────────────────────┐ │
│ │ [Shield] Alpha-1        [2m]     > │ │
│ │ Ground   Cyan Team                 │ │  ← Unit Row
│ │  450m   045° NE                │ │
│ └────────────────────────────────────┘ │
│ ┌────────────────────────────────────┐ │
│ │ [Shield] Bravo-2        [5m]     > │ │
│ │ Ground   Blue Team                 │ │
│ │  1.2km   180° S                │ │
│ └────────────────────────────────────┘ │
│                                        │
│ ▼ HOSTILE (12)                         │  ← Section Header
│ ┌────────────────────────────────────┐ │
│ │ [] Enemy-1          [1h] STALE > │ │
│ │ Air      Unknown                   │ │
│ │  15km   270° W                 │ │
│ └────────────────────────────────────┘ │
│                                        │
│ ▼ UNKNOWN (3)                          │  ← Section Header
│ ┌────────────────────────────────────┐ │
│ │ [?] Contact-X         [30s]      > │ │
│ │ Ground   Unknown                   │ │
│ │  N/A    N/A                    │ │
│ └────────────────────────────────────┘ │
│                                        │
└────────────────────────────────────────┘
```

## Unit Detail Sheet Layout

```
┌────────────────────────────────────────┐
│  Unit Details                    [Done]│  ← Navigation Bar
├────────────────────────────────────────┤
│ ┌────────────────────────────────────┐ │
│ │         [Shield Icon]              │ │
│ │                                    │ │
│ │          Alpha-1                   │ │  ← Header Card
│ │                                    │ │
│ │   [Cyan]  [Friendly]  [Ground]    │ │
│ └────────────────────────────────────┘ │
│                                        │
│ ┌────────────────────────────────────┐ │
│ │ LOCATION                           │ │
│ │ Latitude:    38.897700°            │ │
│ │ Longitude:   -77.036500°           │ │
│ │ Altitude:    50 m / 164 ft         │ │  ← Location Card
│ │ Distance:    450 m                 │ │
│ │ Bearing:     045° (NE)             │ │
│ │ CE:          10.0 m                │ │
│ │ LE:          15.0 m                │ │
│ └────────────────────────────────────┘ │
│                                        │
│ ┌────────────────────────────────────┐ │
│ │ MOVEMENT                           │ │
│ │ Speed:       5.2 m/s (18.7 km/h)   │ │  ← Movement Card
│ │ Course:      045°                  │ │  (optional)
│ └────────────────────────────────────┘ │
│                                        │
│ ┌────────────────────────────────────┐ │
│ │ DETAILS                            │ │
│ │ Age:         2m                    │ │
│ │ Status:      Current               │ │  ← Details Card
│ │ Timestamp:   Nov 8, 2025 12:30 PM  │ │
│ │ Battery:     85%                   │ │
│ │ Device:      Android               │ │
│ └────────────────────────────────────┘ │
│                                        │
│ ┌────────────────────────────────────┐ │
│ │ TECHNICAL INFO                     │ │
│ │ UID:         ANDROID-ABC123        │ │  ← Technical Card
│ │ Type:        a-f-G-E-V             │ │
│ └────────────────────────────────────┘ │
│                                        │
└────────────────────────────────────────┘
```

## Bottom Toolbar Layout

```
┌────────────────────────────────────────────────────────────┐
│ [Layers][Filter][Units]    [GPS][Send][+]  [Measure][Route]│
│                                    [-]                      │
└────────────────────────────────────────────────────────────┘
   └─ Left Tools ─┘  └─Center─┘  └─────── Right Tools ──────┘
```

### Button Details

**Left Section:**
- Layers: Opens layer panel (left)
- Filter: Opens filter panel (right)
- Units: Opens unit list (right)

**Center Section:**
- GPS: Center on user location
- Send: Broadcast position
- +/-: Zoom in/out (stacked)

**Right Section:**
- Measure: Measurement tool (future)
- Route: Route planning (future)

## Color Scheme

### Affiliations
```
Friendly:       Cyan    (#00FFFF)
Hostile:        Red     (#FF0000)
Neutral:        Green   (#00FF00)
Unknown:        Yellow  (#FFFF00)
Assumed Friend: Cyan    (#00FFFF)
Suspect:        Red     (#FF0000)
```

### UI Elements
```
Background:     Black   90-95% opacity
Panel BG:       Black   95% opacity
Highlight:      Cyan    (#00FFFF)
Text:           White   (#FFFFFF)
Secondary:      Gray    (#808080)
Active:         Green   (#00FF00)
Warning:        Orange  (#FFA500)
Error:          Red     (#FF0000)
```

## Panel Behavior

### Panel Transitions
```
Closed → Open:  Slide from edge (0.3s spring animation)
Open → Closed:  Slide to edge (0.3s spring animation)
```

### Panel Interactions
```
Open Layers  → Close Filter/Units
Open Filter  → Close Layers/Units
Open Units   → Close Layers/Filter

Only one panel open at a time
```

### Responsive Layout
```
Portrait:  Panels padding vertical = 120pt
Landscape: Panels padding vertical = 80pt
```

## Icon Reference

### Quick Filters
```
All Units:      square.grid.2x2
Friendly:       shield.fill
Hostile:        exclamationmark.triangle.fill
Nearby:         location.circle.fill
Recent:         clock.fill
Ground:         car.fill
Air:            airplane
```

### Categories
```
Ground:         car.fill
Air:            airplane
Maritime:       ferry.fill
Subsurface:     water.waves
Installation:   building.2.fill
Sensor:         sensor.fill
Equipment:      wrench.and.screwdriver.fill
Other:          mappin.circle.fill
```

### Sort Options
```
Distance:       location.circle
Age:            clock
Callsign:       textformat
Affiliation:    shield.fill
Category:       square.grid.2x2
```

### UI Controls
```
Search:         magnifyingglass
Filter:         line.3.horizontal.decrease.circle.fill
Units:          list.bullet.rectangle
Close:          xmark.circle.fill
Expand:         chevron.right
Collapse:       chevron.down
Sort Asc:       arrow.up
Sort Desc:      arrow.down
```

## Interaction Patterns

### Filter Panel
1. Open filter panel
2. Type in search or select quick filter
3. Toggle affiliations/categories
4. Expand advanced for distance/age
5. Change sort options
6. View statistics
7. Reset if needed

### Unit List
1. Open unit list
2. Scroll through groups
3. Tap on unit
4. View detail sheet
5. Map auto-centers
6. Close detail sheet

### Map Integration
1. Filtered units show on map
2. Legacy overlay filters still work
3. Marker colors match affiliations
4. Tap marker for callout

## Accessibility

### Touch Targets
- Minimum: 44x44 pt
- Buttons: 56x56 pt (toolbar)
- Toggles: Full row height
- Sliders: Full width

### Contrast Ratios
- Text on dark: 12:1 (white on black)
- Highlights: 8:1 (cyan on black)
- Icons: Clear and distinct

### Haptics
- Button tap: Medium impact
- Toggle: Light impact
- Panel open/close: Medium impact

## Performance

### Rendering
- Lazy loading in lists
- Efficient Set operations
- Cached calculations
- 60 FPS animations

### Updates
- Filter on change: Immediate
- Distance calc: Every 5s
- Age update: Every 5s
- Map refresh: On filter change

## Summary

This UI layout provides:
- Intuitive filter controls
- Clear unit organization
- Detailed unit information
- Consistent ATAK styling
- Responsive design
- Smooth interactions
- Professional appearance
