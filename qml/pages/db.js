/*
 * This file is part of harbour-moremahjong.
 * Copyright (C) 2026  blueprint@poetaster.de based on code from
 *
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with harbour-dwd.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

.pragma library
.import QtQuick.LocalStorage 2.0 as LS


function defaultFor(arg, val) { return typeof arg !== 'undefined' ? arg : val; }

var initialized = false;
var debug = true;

function getDatabase() {
    var db = LS.LocalStorage.openDatabaseSync("harbour-moremahjong", "1.0", "Mah Location Cache", 10000);

    if (!initialized) {
        initialized = true;
        doInit(db);
    }

    return db;
}

function doInit(db) {
    // Database tables: (primary key in all-caps)
    // times: BOARD_ID, last_time, best_time, play_count
    // settings: SETTING, value

    db.transaction(function(tx) {
        tx.executeSql('CREATE TABLE IF NOT EXISTS times(\
            board_id INTEGER NOT NULL PRIMARY KEY, last_time TEXT NOT NULL,\
            best_time TEXT NOT NULL, play_count INTEGER NOT NULL DEFAULT 0)');
        tx.executeSql('CREATE TABLE IF NOT EXISTS settings(setting TEXT NOT NULL PRIMARY KEY, value TEXT)');
    });

    // update add cindex column if not already there.
    /*
    try {
        db.transaction(function(tx) {
            var rs = undefined;
            rs = tx.executeSql('SELECT * FROM locations WHERE cindex=?;', [0]);
        });
    } catch(e) {
        if (debug) console.log("cindex query error: '" + e);
        try {
            db.transaction(function(tx) {
            tx.executeSql('ALTER TABLE locations ADD COLUMN cindex INTEGER NOT NULL DEFAULT 9999')
            });
        } catch(b) {
            if (debug) console.log("alter error in query: '" + b);
        }
     }*/
}

function simpleQuery(query, values, getSelectedCount) {
    var db = getDatabase();
    var res = undefined;
    values = defaultFor(values, []);

    if (!query) {
        if (debug) console.log("error: empty query");
        return undefined;
    }

    try {
        db.transaction(function(tx) {
            var rs = tx.executeSql(query, values);

            if (rs.rowsAffected > 0) {
                res = rs.rowsAffected;
            } else {
                res = 0;
            }

            if (getSelectedCount === true) {
                res = rs.rows.length;
            }
        });
    } catch(e) {
        if (debug) console.log("error in query: '"+ e +"', values=", values);
        res = undefined;
    }

    return res;
}

function vacuumDatabase() {
    var db = getDatabase();

    try {
        db.transaction(function(tx) {
            // VACUUM cannot be executed inside a transaction, but the LocalStorage
            // module cannot execute queries without one. Thus we have to manually
            // end the transaction from inside the transaction...
            var rs = tx.executeSql("END TRANSACTION;");
            var rs2 = tx.executeSql("VACUUM;");
        });
    } catch(e) {
        if (debug) console.log("error in query: '"+ e);
    }
}

// ---------------------------------------------------------------------------
// Per-board scores (play count / best time) on top of the times table above:
//   times(board_id INTEGER PRIMARY KEY, last_time TEXT, best_time TEXT,
//         play_count INTEGER)
// Times are stored as milliseconds (strings, '0' = never won).
//
//     import "db.js" as DB
//     DB.loadScores() / DB.recordGame(boardId, won, timeMs) / DB.bestTimeFor(boardId)
//
// ---------------------------------------------------------------------------

function _parseTime(v) {
    if (v === undefined || v === null || v === '')
        return -1;
    var n = parseInt(v, 10);
    return isNaN(n) || n <= 0 ? -1 : n;
}

function _scoreObject(row) {
    if (!row)
        return { playCount: 0, bestTime: -1, lastTime: -1 };
    var pc = parseInt(row.play_count, 10);
    return {
        playCount: isNaN(pc) ? 0 : pc,
        bestTime: _parseTime(row.best_time),
        lastTime: _parseTime(row.last_time)
    };
}

// The row for a board, or undefined when it was never played.
function _rowFor(boardId) {
    var db = getDatabase();
    var row = undefined;
    db.transaction(function(tx) {
        var rs = tx.executeSql('SELECT * FROM times WHERE board_id = ?', [Number(boardId)]);
        if (rs && rs.rows.length > 0)
            row = rs.rows.item(0);
    });
    return row;
}

// All scores as { boardId: { playCount, bestTime, lastTime} } (bestTime is
// -1 when the board was never won).
function loadScores() {
    var db = getDatabase();
    var out = {};
    db.transaction(function(tx) {
        var rs = tx.executeSql('SELECT * FROM times');
        for (var i = 0; i < rs.rows.length; i++) {
            var row = rs.rows.item(i);
            out[String(row.board_id)] = _scoreObject(row);
        }
    });
    return out;
}

// Run a write statement like simpleQuery(), but log the real SQL error
// when it fails (simpleQuery only logs when the debug flag is set).
function _write(query, values) {
    var db = getDatabase();
    var res = undefined;
    try {
        db.transaction(function(tx) {
            var rs = tx.executeSql(query, values);
            res = rs && rs.rowsAffected ? rs.rowsAffected : 0;
        });
    } catch (e) {
        console.log("db: SQL error: '" + e + "' in " + query);
        res = undefined;
    }
    return res;
}
// set or update stored user style/theme
function setTheme(theme){
    var db = getDatabase();
    var query;
    query = 'UPDATE settings SET value = ? WHERE setting = "theme"';
    var row = undefined;
    var r = undefined;
    r =  simpleQuery(query, [theme]);
    console.log(JSON.stringify(r))
    if (r > 0) return 1;
    return "classic"
}

function getTheme() {
    var db = getDatabase();
    var row = undefined;
    db.transaction(function(tx) {
        var rs = tx.executeSql('SELECT * FROM settings WHERE setting = "theme" LIMIT 1', []);
        if (rs && rs.rows.length > 0)
            row = rs.rows.item(0);
    });
    return row;
}

// Record a finished game; returns the (updated) score object for the board.
function recordGame(boardId, won, timeMs) {
    var id = Number(boardId);
    var row = _rowFor(id);
    var s = _scoreObject(row);
    s.playCount += 1;
    if (won && timeMs >= 0 && (s.bestTime < 0 || timeMs < s.bestTime))
        s.bestTime = timeMs;
    if (timeMs >= 0)
        s.lastTime = timeMs;
    // Never bind '' (the module stores it as NULL, which violates the
    // NOT NULL constraints): '0' means "no time recorded".
    var bestStr = s.bestTime >= 0 ? String(s.bestTime) : '0';
    var lastStr = s.lastTime >= 0 ? String(s.lastTime) : '0';
    var ins = 'INSERT INTO times (board_id, last_time, best_time, play_count) VALUES (?, ?, ?, ?)';
    var upd = 'UPDATE times SET last_time = ?, best_time = ?, play_count = ? WHERE board_id = ?';
    var r = row ?
        simpleQuery(upd, [lastStr, bestStr, s.playCount, id]) :
        simpleQuery(ins, [id, lastStr, bestStr, s.playCount]);
    if (r !== 1) {
        // First attempt failed or affected no rows: try the other branch
        // with error logging, so a failure is never silent.
        r = row ?
            _write(ins, [id, lastStr, bestStr, s.playCount]) :
            _write(upd, [lastStr, bestStr, s.playCount, id]);
    }
    if (r !== 1)
        console.log("db: recordGame: could not record board " + id +
                    " (row=" + (row ? "yes" : "no") + ", won=" + won +
                    ", timeMs=" + timeMs + ", values=[" + lastStr + ", " + bestStr + ", " + s.playCount + "])");
    if (!_rowFor(id))
        console.log("db: recordGame: row still missing after write for board " + id);
    return s;
}

// Best winning time (ms) for a board, or -1 when it was never won.
function bestTimeFor(boardId) {
    var row = _rowFor(Number(boardId));
    return row ? _parseTime(row.best_time) : -1;
}

// Forget all scores and best times.
function clearScores() {
    simpleQuery('DELETE FROM times');
    vacuumDatabase();
    return true;
}
