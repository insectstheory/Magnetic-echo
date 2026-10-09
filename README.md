# magnetic echo

Insects Theory 2026

🇬🇧 [English](#english) · 🇮🇹 [Italiano](#italiano)

---

## English

### Description

magnetic echo is a tape echo for [norns](https://monome.org/docs/norns/), built on softcut. It has 1 write head and 4 read heads on a 3.2 s tape loop. Tape speed, head spacing, tape wear, wow & flutter and dropouts all shape the sound of the repeats.

### Installation

1. Copy the script folder to `dust/code/magnetic_echo/` on your norns.
2. The main file must be named `magnetic_echo.lua` (same name as the folder).
3. Reload the script list (or restart the norns) and load magnetic echo from the menu.

### Controls

| Control | Action |
| ENC1 | time (tape speed) |
| ENC2 | repeats |
| ENC3 | mix |
| KEY2 | select head (1–4) |
| KEY3 | selected head mode: off → play → repeat |
| KEY1 (hold) | ALT |
| ALT + ENC1 | spacing (distance between heads) |
| ALT + ENC2 | wear (tape age) |
| ALT + ENC3 | level of the selected head |
| ALT + KEY2 | tape mode: echo → sos → loop |
| ALT + KEY3 | delete (clear the tape) |

### Tape modes

- echo: classic delay. Heads set to repeat feed back into the write head, scaled by `repeats`.
- sos (sound on sound): overdub. New input is recorded on top of the tape, and `repeats` sets how much of the old material is kept.
- loop: freeze. Recording stops and the tape content loops indefinitely.

### Head modes

- off: head is silent.
- play: head is heard in the output only.
- repeat: head is heard and also feeds back into the tape (echo mode).

Default setup: head 1 = repeat, heads 2–4 = play.

### Parameters

| Parameter | Range | Description |
|---|---|---|
| time (tape speed) | 100–1600 ms | delay time, changes the tape speed |
| repeats | 0–1 | feedback / overdub amount |
| mix | 0–1 | dry/wet balance |
| spacing | 0.25–2.0 | distance between the heads |
| wear (tape age) | 0–1 | darker sound, more dropouts and wobble |
| wow & flutter | 0–1 | pitch instability |
| tone | 800–16000 Hz | low-pass filter on the heads |
| stereo spread | 0–1 | stereo width of the heads |
| input level | 0–1 | input gain |
| echo output level | 0–2 | level of the echoes |
| output compressor | off / on | norns output compressor |
| resync heads | trigger | realigns the heads to the writer |
| head 1–4 | off / play / repeat | mode of each head |
| head 1–4 level | 0–1 | level of each head |

### Notes

- Changing `spacing` triggers an automatic resync after a short pause.
- On start there is a short animated intro; controls are disabled until it ends.
- The screen shows the tape path, the heads (outline = play, filled = repeat), and the current values.

---

## Italiano

### Descrizione

magnetic echo è un echo a nastro per [norns](https://monome.org/docs/norns/), basato su softcut. Ha 1 testina di scrittura e 4 di lettura su un loop di nastro di 3,2 s. Velocità del nastro, spaziatura delle testine, usura, wow & flutter e dropout danno carattere alle ripetizioni.

### Installazione

1. Copia la cartella dello script in `dust/code/magnetic_echo/` sul tuo norns.
2. Il file principale deve chiamarsi `magnetic_echo.lua` (stesso nome della cartella).
3. Aggiorna l'elenco degli script (o riavvia il norns) e carica magnetic echo dal menu.

### Controlli

| Controllo | Azione |
| ENC1 | time (velocità del nastro) |
| ENC2 | repeats |
| ENC3 | mix |
| KEY2 | selezione testina (1–4) |
| KEY3 | modalità della testina selezionata: off → play → repeat |
| KEY1 (tenuto) | ALT |
| ALT + ENC1 | spacing (distanza tra le testine) |
| ALT + ENC2 | wear (età del nastro) |
| ALT + ENC3 | livello della testina selezionata |
| ALT + KEY2 | modalità nastro: echo → sos → loop |
| ALT + KEY3 | delete (cancella il nastro) |

### Modalità nastro

- echo: delay classico. Le testine in repeat rientrano nella testina di scrittura, in misura pari a `repeats`.
- sos (sound on sound): overdub. Il nuovo ingresso viene registrato sopra il nastro, e `repeats` stabilisce quanto del materiale precedente viene conservato.
- loop: freeze. La registrazione si ferma e il contenuto del nastro gira all'infinito.

### Modalità testina

- off: la testina è muta.
- play: la testina si sente solo in uscita.
- repeat: la testina si sente e rientra anche nel nastro (modalità echo).

Impostazione predefinita: testina 1 = repeat, testine 2–4 = play.

### Parametri

| Parametro | Intervallo | Descrizione |
|---|---|---|
| time (tape speed) | 100–1600 ms | tempo di delay, cambia la velocità del nastro |
| repeats | 0–1 | quantità di feedback / overdub |
| mix | 0–1 | bilanciamento dry/wet |
| spacing | 0.25–2.0 | distanza tra le testine |
| wear (tape age) | 0–1 | suono più scuro, più dropout e oscillazioni |
| wow & flutter | 0–1 | instabilità di intonazione |
| tone | 800–16000 Hz | filtro passa-basso sulle testine |
| stereo spread | 0–1 | apertura stereo delle testine |
| input level | 0–1 | guadagno d'ingresso |
| echo output level | 0–2 | livello degli echi |
| output compressor | off / on | compressore d'uscita del norns |
| resync heads | trigger | riallinea le testine alla testina di scrittura |
| head 1–4 | off / play / repeat | modalità di ogni testina |
| head 1–4 level | 0–1 | livello di ogni testina |

### Note

- Cambiare `spacing` avvia una risincronizzazione automatica dopo una breve pausa.
- All'avvio c'è una breve intro animata; i controlli sono disattivati finché non finisce.
- Lo schermo mostra il percorso del nastro, le testine (contorno = play, pieno = repeat) e i valori correnti.
