#!/usr/bin/env python3
import json, os, datetime, calendar, shlex, re
from colorama import Fore, Style, init

init(autoreset=True)

EVENTS_FILE = os.path.expanduser("~/.terminal_calendar.json")

def load_events():
    if os.path.exists(EVENTS_FILE):
        with open(EVENTS_FILE, "r") as f:
            return json.load(f)
    return {}

def save_events(events):
    with open(EVENTS_FILE, "w") as f:
        json.dump(events, f, indent=2)

def parse_tags(text):
    tags = re.findall(r"#(\w+)", text)
    clean_text = re.sub(r"#\w+", "", text).strip()
    return clean_text, tags

def add_event(date, text):
    text, tags = parse_tags(text)
    events = load_events()
    events.setdefault(date, []).append({"text": text, "done": False, "tags": tags})
    save_events(events)
    print(f"Evento agregado para {date}: {text} {' '.join('#'+t for t in tags)}")

def mark_done(date, index):
    events = load_events()
    if date not in events or index < 1 or index > len(events[date]):
        print("Evento no encontrado.")
        return
    events[date][index - 1]["done"] = True
    save_events(events)
    print(f"Evento marcado como hecho: {events[date][index - 1]['text']}")

def show_calendar(year, month, events):
    cal = calendar.monthcalendar(year, month)
    print(f"\n   {calendar.month_name[month]} {year}".center(20))
    print("Mo Tu We Th Fr Sa Su")

    for week in cal:
        for day in week:
            if day == 0:
                print("  ", end=" ")
                continue
            date_str = f"{year}-{month:02d}-{day:02d}"
            if date_str in events:
                evs = events[date_str]
                if all(e["done"] for e in evs):
                    color = Fore.GREEN
                elif any(not e["done"] for e in evs):
                    color = Fore.YELLOW
                else:
                    color = Fore.WHITE
                print(color + f"{day:2d}" + Style.RESET_ALL, end=" ")
            else:
                print(f"{day:2d}", end=" ")
        print()

def filter_events(evs, status):
    if status == "done":
        return [e for e in evs if e["done"]]
    elif status == "pending":
        return [e for e in evs if not e["done"]]
    else:
        return evs

def list_events(*args):
    today = datetime.date.today()
    events = load_events()

    # Si no hay argumentos -> calendario actual
    if not args:
        show_calendar(today.year, today.month, events)
        return

    arg1 = args[0]
    status = "pending"  # por defecto mostrar solo pendientes
    include_past = False

    # Buscar posibles parámetros adicionales
    if len(args) > 1:
        for a in args[1:]:
            if a in ["done", "pending", "all"]:
                status = a
            elif a == "past":
                include_past = True

    # Helper para comparar fechas
    def is_future_or_today(date_str):
        y, m, d = map(int, date_str.split("-"))
        return datetime.date(y, m, d) >= today

    # Mostrar por etiqueta
    if arg1.startswith("#"):
        tag = arg1[1:]
        found = False
        for d in sorted(events.keys()):
            if not include_past and not is_future_or_today(d):
                continue
            filtered = [ev for ev in filter_events(events[d], status) if tag in ev.get("tags", [])]
            for ev in filtered:
                if not found:
                    print(f"Eventos con etiqueta #{tag} ({status}):")
                    found = True
                status_mark = "[x]" if ev["done"] else "[ ]"
                print(f"{d} {status_mark} {ev['text']}")
        if not found:
            print("No hay eventos con esos filtros.")
        return

    # Mostrar por día del mes actual
    if arg1.isdigit():
        date_str = f"{today.year}-{today.month:02d}-{int(arg1):02d}"
        if date_str in events:
            evs = filter_events(events[date_str], status)
            if not evs:
                print("No hay eventos con esos filtros.")
                return
            print(f"Eventos del {date_str} ({status}):")
            for i, ev in enumerate(evs, 1):
                status_mark = "[x]" if ev["done"] else "[ ]"
                tags = " ".join(f"#{t}" for t in ev.get("tags", []))
                print(f"{i}. {status_mark} {ev['text']} {tags}")
        else:
            print("No hay eventos ese día.")
        return

    # Mostrar por fecha completa
    if re.match(r"\d{4}-\d{2}-\d{2}", arg1):
        date_str = arg1
        if not include_past and not is_future_or_today(date_str):
            print("Esa fecha ya pasó. Usa 'past' o 'all' para incluirla.")
            return
        if date_str in events:
            evs = filter_events(events[date_str], status)
            if not evs:
                print("No hay eventos con esos filtros.")
                return
            print(f"Eventos del {date_str} ({status}):")
            for i, ev in enumerate(evs, 1):
                status_mark = "[x]" if ev["done"] else "[ ]"
                tags = " ".join(f"#{t}" for t in ev.get("tags", []))
                print(f"{i}. {status_mark} {ev['text']} {tags}")
        else:
            print("No hay eventos ese día.")
        return

    # Mostrar por mes y año
    if re.match(r"\d{4}-\d{2}", arg1):
        y, m = map(int, arg1.split("-"))
        show_calendar(y, m, events)
        return

    print("Argumento no reconocido. Usa 'help' para más información.")

def help_menu():
    print("""
Comandos disponibles:
  add YYYY-MM-DD "texto" [#tag1 #tag2]      → Agrega evento con etiquetas
  list [día | YYYY-MM | YYYY-MM-DD | #tag] [pending|done|all] [past] 
       → Muestra calendario o lista de eventos según filtros
  done YYYY-MM-DD N                         → Marca evento N como hecho
  help                                      → Muestra este menú
  exit                                      → Salir

Colores en calendario:
  Verde   = todos hechos
  Amarillo = hay pendientes
  Blanco  = sin eventos
    """)

def main():
    print("Terminal Calendar — escribe 'help' para ver los comandos.\n")
    while True:
        try:
            cmd = input("> ").strip()
            if not cmd:
                continue
            parts = shlex.split(cmd)
            command = parts[0]

            if command == "add" and len(parts) >= 3:
                add_event(parts[1], " ".join(parts[2:]))
            elif command == "list":
                list_events(*parts[1:])
            elif command == "done" and len(parts) == 3:
                mark_done(parts[1], int(parts[2]))
            elif command == "help":
                help_menu()
            elif command in ["exit", "quit"]:
                break
            else:
                print("Comando no reconocido. Usa 'help' para ayuda.")
        except KeyboardInterrupt:
            print("\nSaliendo.")
            break
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    main()

