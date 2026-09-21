// Shared helpers for the QML port of mah (https://ffalt.github.io/mah).
// Instantiate from QML:
//     import "."
//     MahData { id: mah }
//
// The geometry, blocking and tile rules mirror the original JS sources
// (webpack modules 1344, 2878, 3378, 5050, 8219 in qml/mah/main.*.js):
//   tile size   75 x 100
//   px = (75+2)*x/2 - 8*z + 75/2
//   py = (100+2)*y/2 - 8*z + 100/2
//   paint order z = y + 18*(x + 38*z)   (higher paints on top)
//   a tile is blocked if a stone rests on top of it, or stones rest on
//   both its left and right side.

var TILE_W = 75
var TILE_H = 100
var MY = 18
var MX = 38

// 36 groups of 4 identical tiles, in the original order (module 1344 B8):
// 9 circles, 9 characters, 9 bamboo, 4 seasons, 4 winds, 4 flowers, 3 dragons.
var TILE_GROUPS = [
    ["t_do1", "t_do1", "t_do1", "t_do1"],
    ["t_do2", "t_do2", "t_do2", "t_do2"],
    ["t_do3", "t_do3", "t_do3", "t_do3"],
    ["t_do4", "t_do4", "t_do4", "t_do4"],
    ["t_do5", "t_do5", "t_do5", "t_do5"],
    ["t_do6", "t_do6", "t_do6", "t_do6"],
    ["t_do7", "t_do7", "t_do7", "t_do7"],
    ["t_do8", "t_do8", "t_do8", "t_do8"],
    ["t_do9", "t_do9", "t_do9", "t_do9"],
    ["t_ch1", "t_ch1", "t_ch1", "t_ch1"],
    ["t_ch2", "t_ch2", "t_ch2", "t_ch2"],
    ["t_ch3", "t_ch3", "t_ch3", "t_ch3"],
    ["t_ch4", "t_ch4", "t_ch4", "t_ch4"],
    ["t_ch5", "t_ch5", "t_ch5", "t_ch5"],
    ["t_ch6", "t_ch6", "t_ch6", "t_ch6"],
    ["t_ch7", "t_ch7", "t_ch7", "t_ch7"],
    ["t_ch8", "t_ch8", "t_ch8", "t_ch8"],
    ["t_ch9", "t_ch9", "t_ch9", "t_ch9"],
    ["t_ba1", "t_ba1", "t_ba1", "t_ba1"],
    ["t_ba2", "t_ba2", "t_ba2", "t_ba2"],
    ["t_ba3", "t_ba3", "t_ba3", "t_ba3"],
    ["t_ba4", "t_ba4", "t_ba4", "t_ba4"],
    ["t_ba5", "t_ba5", "t_ba5", "t_ba5"],
    ["t_ba6", "t_ba6", "t_ba6", "t_ba6"],
    ["t_ba7", "t_ba7", "t_ba7", "t_ba7"],
    ["t_ba8", "t_ba8", "t_ba8", "t_ba8"],
    ["t_ba9", "t_ba9", "t_ba9", "t_ba9"],
    ["t_se_spring", "t_se_summer", "t_se_fall", "t_se_winter"],
    ["t_wi_north", "t_wi_north", "t_wi_north", "t_wi_north"],
    ["t_wi_south", "t_wi_south", "t_wi_south", "t_wi_south"],
    ["t_wi_east", "t_wi_east", "t_wi_east", "t_wi_east"],
    ["t_wi_west", "t_wi_west", "t_wi_west", "t_wi_west"],
    ["t_fl_bamboo", "t_fl_chrysanthemum", "t_fl_orchid", "t_fl_plum"],
    ["t_dr_green", "t_dr_green", "t_dr_green", "t_dr_green"],
    ["t_dr_white", "t_dr_white", "t_dr_white", "t_dr_white"],
    ["t_dr_red", "t_dr_red", "t_dr_red", "t_dr_red"]
]

function assetBase() {
    return Qt.resolvedUrl("../mah/assets/").toString()
}

function loadJSON(file, callback) {

   var xobj = new XMLHttpRequest();
   //xobj.overrideMimeType("application/json");
   xobj.open('GET', file, true);
   xobj.onreadystatechange = function () {
       if (xobj.readyState === XMLHttpRequest.DONE) {
           callback(xobj);
       }
   };
   //xobj.open("GET",file)
   xobj.send();
}

function loadBoards() {
    var response; // Qt.ope (Qt.resolvedUrl("../mah/assets/data/boards.json"))
    var out = []
    loadJSON("../mah/assets/data/boards.json", function(doc) {
        response = JSON.parse(doc.responseText);
        //var arr = resp.data
        for (var i = 0; i < response.length ; i++) {
            //page.boards.push({ id: response[i].id, name: response[i].name, map: response[i].map })
             //boards.append(response[i]);
             boards[i] = response[i];
            console.debug(JSON.stringify(boards[i].name))
        };
        //return out
    });
    return out
}
function findBoard(boards,bid) {
    var bs = boards;
    for (var i = 0; i < bs.length; i++) {
        if (bs[i] && String(bs[i].id) === String(bid))
            return bs[i]
    }
    console.log("findBoard: no match for bid=" + bid + " (" + (typeof bid) + ")")
    return undefined
}

// Expand a board map into the list of stone positions [{z, x, y}].
// Same algorithm as the original parser (webpack module 2878).
function parseBoard(map) {
    var out = []
    for (var i = 0; i < map.length; i++) {
        var z = map[i][0]
        var entries = map[i][1]
        for (var e = 0; e < entries.length; e++) {
            var y = entries[e][0]
            var rest = entries[e][1]
            if (Object.prototype.toString.call(rest) === "[object Array]") {
                for (var r = 0; r < rest.length; r++) {
                    var it = rest[r]
                    if (Object.prototype.toString.call(it) === "[object Array]") {
                        var x = it[0]
                        var count = it[1]
                        for (var c = 0; c < count; c++) {
                            out.push({ z: z, x: x, y: y })
                            x += 2
                        }
                    } else {
                        out.push({ z: z, x: it, y: y })
                    }
                }
            } else {
                out.push({ z: z, x: rest, y: y })
            }
        }
    }
    return out
}

// Screen-space position + paint order for a stone (module 8219).
function tilePos(z, x, y) {
    return {
        px: (TILE_W + 2) * x / 2 - 8 * z + TILE_W / 2,
        py: (TILE_H + 2) * y / 2 - 8 * z + TILE_H / 2,
        z: z,
        zsort: y + MY * (x + MX * z)
    }
}

// The tiles to deal for a board with `count` slots: the first
// ceil(count / 4) groups of the standard set (module 2240).
function tilesFor(count) {
    var nGroups = Math.ceil(count / 4)
    if (nGroups > TILE_GROUPS.length)
        nGroups = TILE_GROUPS.length
    var out = []
    for (var g = 0; g < nGroups; g++)
        for (var t = 0; t < 4; t++)
            out.push({ v: TILE_GROUPS[g][t], groupnr: g })
    return out.length > count ? out.slice(0, count) : out
}

// Map a tile id to the matching classic png (absolute file url).
function imageFor(v) {
    if (!v)
        return ""
    var s = String(v)
    if (s.substring(0, 2) === "t_")
        s = s.substring(2)
    var m = s.match(/^([a-z]+)(\d+)$/)
    if (m) {
        var suit = null
        if (m[1] === "do")
            suit = "ball"
        else if (m[1] === "ch")
            suit = "character"
        else if (m[1] === "ba")
            suit = "bamboo"
        if (suit)
            return assetBase() + "svg/classic/" + suit + "_" + m[2] + ".png"
    }
    m = s.match(/^([a-z]+)_([a-z]+)$/)
    if (m) {
        var pref = null
        if (m[1] === "se")
            pref = "season"
        else if (m[1] === "wi")
            pref = "wind"
        else if (m[1] === "fl")
            pref = "flower"
        else if (m[1] === "dr")
            pref = "dragon"
        if (pref)
            return assetBase() + "svg/classic/" + pref + "_" + m[2] + ".png"
    }
    return ""
}

// ---------------------------------------------------------------------------
// Game engine (ported from webpack modules 5050, 3378, 4678, 5405, 6779).
// A game state `g` looks like:
//   { stones: [{z,x,y,v,groupnr,picked,blocked,removable,hinted}],
//     nb:     [{left,right,top,bottom} per stone, neighbor indices],
//     free:   [indices of removable stones],
//     count:  remaining stones, selected: index or -1, undo: [[z,x,y],...],
//     hintGroups: [{group, stones:[]}], hintCurrent: index or -1 }
// ---------------------------------------------------------------------------

function stoneKey(z, x, y) {
    return z + "," + x + "," + y
}

function makeIndex(stones) {
    var idx = {}
    for (var i = 0; i < stones.length; i++)
        idx[stoneKey(stones[i].z, stones[i].x, stones[i].y)] = i
    return idx
}

// Neighbor collection, same as module 3378 collectNodes (indexes of stones).
function neighbors(idx, s) {
    var left = [], right = [], top = [], bottom = []
    function get(z, x, y) {
        var k = stoneKey(z, x, y)
        return Object.prototype.hasOwnProperty.call(idx, k) ? idx[k] : -1
    }
    for (var dy = -1; dy <= 1; dy++) {
        var li = get(s.z, s.x - 2, s.y + dy)
        if (li >= 0) left.push(li)
        var ri = get(s.z, s.x + 2, s.y + dy)
        if (ri >= 0) right.push(ri)
        for (var dx = -1; dx <= 1; dx++) {
            var ti = get(s.z + 1, s.x + dx, s.y + dy)
            if (ti >= 0) top.push(ti)
            var bi = get(s.z - 1, s.x + dx, s.y + dy)
            if (bi >= 0) bottom.push(bi)
        }
    }
    return { left: left, right: right, top: top, bottom: bottom }
}

// Blocked: a stone on top, or stones on both left and right (module 5050).
function isBlocked(stones, nb) {
    function has(arr) {
        for (var i = 0; i < arr.length; i++)
            if (!stones[arr[i]].picked)
                return true
        return false
    }
    return has(nb.top) || (has(nb.left) && has(nb.right))
}

function buildNbs(stones) {
    var idx = makeIndex(stones)
    var nb = []
    for (var i = 0; i < stones.length; i++)
        nb.push(neighbors(idx, stones[i]))
    return nb
}

// Recompute blocked/removable/free/count (module 6779 update).
function updateGame(g) {
    var i, s, count = 0
    for (i = 0; i < g.stones.length; i++) {
        s = g.stones[i]
        if (s.picked) {
            s.blocked = false
            s.removable = false
            continue
        }
        s.blocked = isBlocked(g.stones, g.nb[i])
        count++
    }
    // free = unpicked, unblocked and at least one other unpicked unblocked
    // stone of the same group exists (canRemove, group excludes self).
    var groupFree = {}
    for (i = 0; i < g.stones.length; i++) {
        s = g.stones[i]
        if (!s.picked && !s.blocked)
            groupFree[s.groupnr] = (groupFree[s.groupnr] || 0) + 1
    }
    var free = []
    for (i = 0; i < g.stones.length; i++) {
        s = g.stones[i]
        s.removable = !s.picked && !s.blocked && groupFree[s.groupnr] > 1
        if (s.removable)
            free.push(i)
    }
    g.free = free
    g.count = count
    return g
}

function groupsFromTiles(tiles) {
    var out = []
    for (var i = 0; i < tiles.length; i++) {
        var gnr = tiles[i].groupnr
        if (out[gnr] === undefined)
            out[gnr] = { v: gnr, tiles: [] }
        out[gnr].tiles.push(tiles[i])
    }
    var res = []
    for (var g = 0; g < out.length; g++)
        if (out[g] !== undefined)
            res.push(out[g])
    return res
}

// Try to play the board to completion with random moves; returns the list of
// placed pairs on success, null if a dead end was hit (module 4678 solve).
function solveOnce(stones, nb, groups, slots) {
    var placed = []
    var queue = []
    var need = slots.length / 2
    var gs = groups.slice()
    while (gs.length > 0) {
        var grp = gs.splice(Math.floor(Math.random() * gs.length), 1)[0]
        var ts = grp.tiles.slice()
        var t0 = ts.splice(Math.floor(Math.random() * ts.length), 1)[0]
        var t1 = ts.splice(Math.floor(Math.random() * ts.length), 1)[0]
        var t2 = ts.splice(Math.floor(Math.random() * ts.length), 1)[0]
        var t3 = ts[0]
        if (queue.length < need)
            queue.push([t0, t1])
        if (queue.length < need)
            queue.push([t2, t3])
    }
    while (queue.length > 0) {
        var pair = queue.splice(Math.floor(Math.random() * queue.length), 1)[0]
        var free = []
        for (var i = 0; i < stones.length; i++)
            if (!stones[i].picked && !isBlocked(stones, nb[i]))
                free.push(i)
        if (free.length < 2)
            return null
        var a = free.splice(Math.floor(Math.random() * free.length), 1)[0]
        var b = free.splice(Math.floor(Math.random() * free.length), 1)[0]
        stones[a].v = pair[0].v
        stones[a].groupnr = pair[0].groupnr
        stones[a].picked = true
        stones[b].v = pair[1].v
        stones[b].groupnr = pair[1].groupnr
        stones[b].picked = true
        placed.push(pair)
    }
    return placed
}

// Deal a new board: solvable random assignment of tiles to the slots
// (modules 4678/5405), falling back to a pure random assignment.
// Like the original, the pair queue is drawn from the full 36-group set
// even for boards with fewer than 144 stones.
function dealBoard(board) {
    var slots = parseBoard(board.map)
    var tiles = tilesFor(slots.length)
    var groups = groupsFromTiles(tilesFor(TILE_GROUPS.length * 4))
    var stones = []
    var i
    for (i = 0; i < slots.length; i++)
        stones.push({ z: slots[i].z, x: slots[i].x, y: slots[i].y, v: 0, groupnr: 0, picked: false, blocked: false, removable: false, hinted: false })

    var nb = buildNbs(stones)
    var solved = false
    for (var attempt = 1; attempt <= 1000 && !solved; attempt++) {
        for (i = 0; i < stones.length; i++) {
            stones[i].v = 0
            stones[i].groupnr = 0
            stones[i].picked = false
        }
        solved = solveOnce(stones, nb, groups, slots) !== null
    }
    if (!solved) {
        // Random fallback (module 5405): assign tiles to slots at random.
        var pool = tiles.slice()
        var sl = slots.slice()
        stones = []
        while (sl.length > 0) {
            var t = pool.splice(Math.floor(Math.random() * pool.length), 1)[0]
            var s2 = sl.splice(Math.floor(Math.random() * sl.length), 1)[0]
            stones.push({ z: s2.z, x: s2.x, y: s2.y, v: t.v, groupnr: t.groupnr, picked: false, blocked: false, removable: false, hinted: false })
        }
        nb = buildNbs(stones)
    }
    for (i = 0; i < stones.length; i++)
        stones[i].picked = false

    var g = {
        stones: stones,
        nb: nb,
        free: [],
        count: stones.length,
        selected: -1,
        undo: [],
        hintGroups: [],
        hintCurrent: -1
    }
    return updateGame(g)
}

function clearSelection(g) {
    if (g.selected >= 0 && g.stones[g.selected])
        g.stones[g.selected].selected = false
    g.selected = -1
}

function clearHints(g) {
    if (g.hintCurrent >= 0 && g.hintGroups[g.hintCurrent]) {
        var st = g.hintGroups[g.hintCurrent].stones
        for (var i = 0; i < st.length; i++) {
            var s = g.stones[st[i]]
            if (s)
                s.hinted = false
        }
    }
    g.hintGroups = []
    g.hintCurrent = -1
}

// Pick a matching pair (module 6779 pick). a/b are stone indexes.
function pickPair(g, a, b) {
    clearSelection(g)
    g.undo.push([g.stones[a].z, g.stones[a].x, g.stones[a].y])
    g.undo.push([g.stones[b].z, g.stones[b].x, g.stones[b].y])
    clearHints(g)
    g.stones[a].picked = true
    g.stones[b].picked = true
    return updateGame(g)
}

// Undo the last pick (module 6779 back). Returns true when something undone.
function back(g) {
    if (g.undo.length < 2)
        return false
    var one = g.undo.pop()
    var two = g.undo.pop()
    clearSelection(g)
    clearHints(g)
    for (var i = 0; i < g.stones.length; i++) {
        var s = g.stones[i]
        if ((s.z === one[0] && s.x === one[1] && s.y === one[2]) ||
            (s.z === two[0] && s.x === two[1] && s.y === two[2]))
            s.picked = false
    }
    return updateGame(g)
}

function collectHints(g) {
    var m = {}
    var order = []
    for (var i = 0; i < g.free.length; i++) {
        var idx = g.free[i]
        var gnr = g.stones[idx].groupnr
        if (m[gnr] === undefined) {
            m[gnr] = []
            order.push(gnr)
        }
        m[gnr].push(idx)
    }
    var out = []
    for (i = 0; i < order.length; i++)
        out.push({ group: order[i], stones: m[order[i]] })
    return out
}

function markHint(g) {
    var cur = g.hintGroups[g.hintCurrent]
    if (cur)
        for (var i = 0; i < cur.stones.length; i++)
            g.stones[cur.stones[i]].hinted = true
}

// Hint the next pair (module 6779 hint/hintNext/collectHints).
function hint(g) {
    if (g.hintCurrent >= 0 && g.hintGroups.length > 0) {
        // Cycle to the next group (hintNext).
        for (var i = 0; i < g.hintGroups[g.hintCurrent].stones.length; i++)
            g.stones[g.hintGroups[g.hintCurrent].stones[i]].hinted = false
        var idx = g.hintCurrent + 1
        if (idx >= g.hintGroups.length)
            idx = 0
        g.hintCurrent = idx
        markHint(g)
        return true
    }
    clearHints(g)
    if (g.free.length === 0)
        return false
    var groups = collectHints(g)
    if (g.selected >= 0) {
        var sel = g.stones[g.selected].groupnr
        groups.sort(function (a, b) {
            if (a.group === sel) return -1
            if (b.group === sel) return 1
            return 0
        })
    }
    g.hintGroups = groups
    g.hintCurrent = 0
    markHint(g)
    return true
}

// Shuffle: rebuild the unpicked part solvably and re-place the removed
// tiles (module 6779 shuffle, easy mode only).
function shuffleGame(g) {
    var slots = []
    for (var i = 0; i < g.stones.length; i++)
        if (!g.stones[i].picked)
            slots.push({ z: g.stones[i].z, x: g.stones[i].x, y: g.stones[i].y })
    var tiles = tilesFor(g.stones.length)
    var groups = groupsFromTiles(tiles)
    var stones = []
    for (i = 0; i < slots.length; i++)
        stones.push({ z: slots[i].z, x: slots[i].x, y: slots[i].y, v: 0, groupnr: 0, picked: false, blocked: false, removable: false, hinted: false })

    var nb = buildNbs(stones)
    var solved = false
    for (var attempt = 1; attempt <= 1000 && !solved; attempt++) {
        for (i = 0; i < stones.length; i++) {
            stones[i].v = 0
            stones[i].groupnr = 0
            stones[i].picked = false
        }
        solved = solveOnce(stones, nb, groups, slots) !== null
    }
    if (!solved) {
        var pool = tiles.slice()
        var sl = slots.slice()
        stones = []
        while (sl.length > 0) {
            var t = pool.splice(Math.floor(Math.random() * pool.length), 1)[0]
            var s2 = sl.splice(Math.floor(Math.random() * sl.length), 1)[0]
            stones.push({ z: s2.z, x: s2.x, y: s2.y, v: t.v, groupnr: t.groupnr, picked: false, blocked: false, removable: false, hinted: false })
        }
        nb = buildNbs(stones)
    }
    // Tiles not used by the fresh assignment go back to the removed stones
    // (module 6779 shuffle: M.list minus the built assignment).
    // Tile ids repeat within a group (4x t_do1), so count usage per id.
    var avail = {}
    for (i = 0; i < tiles.length; i++)
        avail[tiles[i].v] = (avail[tiles[i].v] || 0) + 1
    for (i = 0; i < stones.length; i++)
        if (avail[stones[i].v])
            avail[stones[i].v]--
    var rest = []
    for (i = 0; i < tiles.length; i++) {
        if (avail[tiles[i].v] > 0) {
            avail[tiles[i].v]--
            rest.push(tiles[i])
        }
    }
    for (i = 0; i < g.undo.length; i++) {
        var t = rest.shift()
        if (!t)
            break
        var u = g.undo[i]
        stones.push({ z: u[0], x: u[1], y: u[2], v: t.v, groupnr: t.groupnr, picked: true, blocked: false, removable: false, hinted: false })
    }
    g.stones = stones
    g.nb = nb
    clearSelection(g)
    clearHints(g)
    return updateGame(g)
}

// ---------------------------------------------------------------------------
// Per-board scores (play count / best time) in a small JSON file.
// Replaces the localStorage based storage of the original app.
// ---------------------------------------------------------------------------

function scoresPath() {
    return;

    var base = Qt.application ? Qt.application.storageLocation : ""
    if (!base)
        base = "."
    return base + "/mah-scores.json"
}

function loadScores() {
    return {}; // scores storage stubbed out; no persisted scores yet
   // var resp = Qt.openUrlFromFile(Qt.resolvedUrl(scoresPath()))
    if (resp && resp.data !== undefined) {
        var d = resp.data
        if (typeof d === "string")
            try { return JSON.parse(d) } catch (err) { return {} }
        if (d && typeof d === "object")
            return d
    }
    return {}
}

function saveScores(scores) {
    return;
    var f = open(scoresPath(), "w")
    f.write(JSON.stringify(scores))
    f.close()
}

// Record a finished game; returns the (updated) score object for the board.
function recordGame(boardId, won, timeMs) {
    var scores = loadScores()
    var id = String(boardId)
    var s = scores[id] || { playCount: 0, bestTime: -1 }
    s.playCount = (s.playCount || 0) + 1
    if (won && timeMs >= 0 && (s.bestTime < 0 || s.bestTime > timeMs))
        s.bestTime = timeMs
    scores[id] = s
    saveScores(scores)
    return s
}

function bestTimeFor(boardId) {
    var s = loadScores()[String(boardId)]
    return s && s.bestTime ? s.bestTime : -1
}

// In-place Fisher-Yates shuffle.
function shuffle(arr) {
    for (var i = arr.length - 1; i > 0; i--) {
        var j = Math.floor(Math.random() * (i + 1))
        var tmp = arr[i]
        arr[i] = arr[j]
        arr[j] = tmp
    }
    return arr
}

// Pre-scaled miniature of a board for the selection list.
// fitW/fitH: maximum width/height of the miniature in pixels.
function previewTiles(map, fitW, fitH) {
    if (fitH === undefined)
        fitH = Infinity
    var slots = parseBoard(map)
    var minx = Infinity, miny = Infinity, maxx = -Infinity, maxy = -Infinity
    var pts = []
    for (var i = 0; i < slots.length; i++) {
        var p = tilePos(slots[i].z, slots[i].x, slots[i].y)
        pts.push(p)
        if (p.px < minx) minx = p.px
        if (p.py < miny) miny = p.py
        if (p.px + TILE_W > maxx) maxx = p.px + TILE_W
        if (p.py + TILE_H > maxy) maxy = p.py + TILE_H
    }
    var sc = Math.min(fitW / (maxx - minx), fitH / (maxy - miny))
    var tiles = []
    // 4px gap between tiles: shrink each tile by 4px, centered in its cell.
    for (i = 0; i < pts.length; i++)
        tiles.push({
            x: (pts[i].px - minx) * sc + 2,
            y: (pts[i].py - miny) * sc + 2,
            w: Math.max(1, TILE_W * sc - 4),
            h: Math.max(1, TILE_H * sc - 4),
            zsort: pts[i].zsort
        })
    // Paint order: same z-index scheme as the original 2D renderer.
    tiles.sort(function (a, b) { return a.zsort - b.zsort })
    return { tiles: tiles, height: (maxy - miny) * sc, count: slots.length }
}

// Bounding box (board coordinates) of a full board, used to fit the board
// into the play area.
function boardBox(map) {
    var slots = parseBoard(map)
    var minx = Infinity, miny = Infinity, maxx = -Infinity, maxy = -Infinity
    for (var i = 0; i < slots.length; i++) {
        var p = tilePos(slots[i].z, slots[i].x, slots[i].y)
        if (p.px < minx) minx = p.px
        if (p.py < miny) miny = p.py
        if (p.px + TILE_W > maxx) maxx = p.px + TILE_W
        if (p.py + TILE_H > maxy) maxy = p.py + TILE_H
    }
    return { minx: minx, miny: miny, w: maxx - minx, h: maxy - miny }
}

// mm:ss from milliseconds.
function formatTime(ms) {
    var s = Math.floor(ms / 1000)
    var m = Math.floor(s / 60)
    s = s % 60
    return m + ":" + (s < 10 ? "0" : "") + s
}
