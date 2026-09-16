#!/usr/bin/env python3
import glob
import sqlite3
import datetime
import sys
import json

def parse_date(s):
    if not s: return None
    try:
        s = s.strip().replace("'", "")
        return datetime.datetime.strptime(s[:8], '%Y%m%d').date()
    except:
        return None

def format_time(time_str):
    if not time_str or len(time_str) < 14:
        return "All Day"
    try:
        time_str = time_str.strip().replace("'", "")
        if time_str[8:14] == "000000":
            return "All Day"
        hh = int(time_str[8:10])
        mm = int(time_str[10:12])
        ampm = "PM" if hh >= 12 else "AM"
        hh = hh % 12
        hh = 12 if hh == 0 else hh
        return f"{hh:02d}:{mm:02d} {ampm}"
    except:
        return "All Day"

def main():
    if len(sys.argv) < 2:
        target_date = datetime.date.today()
    else:
        try:
            target_date = datetime.datetime.strptime(sys.argv[1], '%Y-%m-%d').date()
        except:
            target_date = datetime.date.today()
            
    events = []
    seen_uids = set()
    
    for db in glob.glob('/home/priyam/.cache/evolution/calendar/*/cache.db'):
        conn = sqlite3.connect(db)
        c = conn.cursor()
        try:
            c.execute('SELECT ECacheUID, summary, occur_start, occur_end, location, description FROM ECacheObjects WHERE summary IS NOT NULL')
            for row in c.fetchall():
                uid, summary, start_str, end_str, loc, desc = row
                if uid in seen_uids:
                    continue
                
                start_d = parse_date(start_str)
                end_d = parse_date(end_str)
                if not start_d: continue
                
                is_recurring = end_d and end_d.year >= 2037
                
                matches = False
                if is_recurring:
                    matches = (start_d.month == target_date.month and start_d.day == target_date.day)
                else:
                    if end_d:
                        matches = (start_d <= target_date <= end_d)
                    else:
                        matches = (start_d == target_date)
                
                if matches:
                    seen_uids.add(uid)
                    
                    is_bday = "birthday" in summary.lower() or "anni" in summary.lower()
                    color = "#ffb4ab" if is_bday else "#bbc3ff"
                    
                    time_formatted = format_time(start_str)
                    
                    events.append({
                        'title': summary.title(),
                        'time': time_formatted,
                        'location': loc or "",
                        'description': desc or "",
                        'color': color
                    })
        except Exception as e:
            pass
            
    def get_sort_key(ev):
        t = ev['time']
        if t == "All Day":
            return (0, 0, 0)
        try:
            parts = t.split()
            h, m = map(int, parts[0].split(':'))
            ampm = parts[1]
            if ampm == "PM" and h < 12:
                h += 12
            if ampm == "AM" and h == 12:
                h = 0
            return (1, h, m)
        except:
            return (2, 0, 0)
            
    events.sort(key=get_sort_key)
    
    print(json.dumps(events))

if __name__ == '__main__':
    main()
