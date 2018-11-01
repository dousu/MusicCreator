<template>
  <div class="hello">
    <textarea id="abc-source"></textarea>
    <textarea id="abc-phrase"></textarea>
    <textarea id="abc-creation"></textarea>
    <audio id="sound-file-click" preload="auto">
	    <source src="static/sound/click/nc112322.wav" type="audio/wav">
    </audio>
    <audio id="sound-file-clear" preload="auto">
	    <source src="static/sound/clear/nc78407.mp3" type="audio/mp3">
    </audio>
    <audio id="sound-file-add" preload="auto">
	    <source src="static/sound/add/nc44409.mp3" type="audio/mp3">
    </audio>
    <audio id="sound-file-undo" preload="auto">
	    <source src="static/sound/undo/nc78408.mp3" type="audio/mp3">
    </audio>
    <audio id="sound-file-button" preload="auto">
	    <source src="static/sound/button/nc167288.mp3" type="audio/mp3">
    </audio>
    <audio id="sound-file-failed" preload="auto">
	    <source src="static/sound/failed/nc45878.mp3" type="audio/mp3">
    </audio>

    <p>
      <big>
        <font size="+5">
          <strong>
            Music Creator
          </strong>
        </font>
        <br> Please select consecutive notes on scores to make a new score.
        <br> Push "Add" button to add "Phrase Editor" to your "Music". 
      </big>
    </p>
    
    <div id="play-info">
      <div class="listener-output">
        <div class="label">Currently Playing: <span class="abc-string">{{currentAbcFragment}}</span></div>
        <div class="label">Parameters sent to listener callback: </div>
        <div>Progress: {{progress.progress }}</div>
        <div>Current Time: {{progress.currentTime }}</div>
        <div>Total Duration: {{progress.duration }}</div>
        <div>New Beat? {{progress.newBeat }}</div>
      </div>
    </div>
    
    <div id="refer-abc">
      <div class="container">
        <div id="paper"></div>
      </div>
      <button v-on:click="leftbutton" class="direction">
        <font-awesome-icon icon="chevron-left" />
      </button>
      <button v-on:click="rightbutton" class="direction">
        <font-awesome-icon icon="chevron-right" />
      </button>
      <div id="midi"></div>
      <div id="midi-download"></div>
    </div>

    <div id=editing>
      <div class="note">
        <p id="editing-alert">
        </p>
      </div>
      <div class="container">
        <div id="paper-phrase"></div>
      </div>
      <button v-on:click="clear_phrase" class="modifier">
        <font-awesome-icon icon="minus" /> clear
      </button>
      <button v-on:click="regist_phrase" class="modifier">
        <font-awesome-icon icon="plus" /> add
      </button>
      <div id="midi-phrase"></div>
      <div id="midi-download-phrase"></div>
    </div>

    <div id="creation">
      <div class="music">
        <div id="paper-creation"></div>
      </div>
      <button v-on:click="clear_creation" class="modifier">
        <font-awesome-icon icon="minus" /> clear
      </button>
      <button v-on:click="undo_creation" class="modifier">
        <font-awesome-icon icon="undo" /> undo
      </button>
      <div id="midi-creation"></div>
      <div id="midi-download-creation"></div>
    </div>
  </div>
</template>

<script>
import "font-awesome/css/font-awesome.min.css";
import "abcjs/abcjs-midi.css";
import abcjs from "abcjs/midi";

export default {
  mounted: async function() {
    await fetch("./static/index.json")
      .then(response => {
        return response.json();
      })
      .then(jsondata => {
        this.allrefdata = jsondata;
      });
    this.abcdata = this.allrefdata[this.refloc];
    this.editingdata = this.tune;
  },
  name: "hello",
  data() {
    return {
      abcdata: "",
      editingdata: "",
      creationdata: "",
      progress: {},
      currentAbcFragment: "(none)",
      tune: "X:1\nT:Phrase Editor\nM:4/4\nL:1/8\nQ:100\nK:C\n",
      allrefdata: [],
      refloc: 0,
      old_creation: [],
      lastelem: "",
      lastscore: ""
    };
  },
  watch: {
    abcdata() {
      document.getElementById("abc-source").value = this.abcdata;
      new abcjs.Editor("abc-source", {
        paper_id: "paper",
        staffwidth: 740,
        generate_midi: true,
        midi_id: "midi",
        midi_download_id: "midi-download",
        abcjsParams: {
          generateDownload: true,
          clickListener: this.selectionCallback,
          midiListener: this.listener,
          animate: {
            listener: this.animate
          }
        }
      });
    },
    editingdata() {
      document.getElementById("abc-phrase").value = this.editingdata;
      new abcjs.Editor("abc-phrase", {
        paper_id: "paper-phrase",
        staffwidth: 740,
        generate_midi: true,
        midi_id: "midi-phrase",
        midi_download_id: "midi-download-phrase",
        abcjsParams: {
          generateDownload: true,
          midiListener: this.listener,
          animate: {
            listener: this.animate
          }
        }
      });
    },
    creationdata() {
      document.getElementById("abc-creation").value = this.creationdata;
      new abcjs.Editor("abc-creation", {
        paper_id: "paper-creation",
        staffwidth: 740,
        generate_midi: true,
        midi_id: "midi-creation",
        midi_download_id: "midi-download-creation",
        abcjsParams: {
          generateDownload: true,
          midiListener: this.listener,
          animate: {
            listener: this.animate
          }
        }
      });
    }
  },
  methods: {
    listener(midiControl, progress) {
      this.progress = progress;
    },
    colorRange(range, color) {
      if (range && range.elements) {
        range.elements.forEach(function(set) {
          set.forEach(function(item) {
            item.setAttribute("fill", color);
          });
        });
      }
    },
    animate(lastRange, currentRange) {
      // This provides the actual visual note being played. It can be used to create the "bouncing ball" effect.
      this.colorRange(lastRange, "#000000"); // Set the old note back to black.
      this.colorRange(currentRange, "#3D9AFC"); // Set the currently sounding note to blue.
    },
    async selectionCallback(abcelem) {
      const val = await this.elemContinuty(abcelem);
      // console.log(val);

      if (val > 0) {
        this.soundClick();
        console.log(val);
        const data = document.getElementById("abc-source").value;
        const targ_data = data.slice(abcelem.startChar, abcelem.endChar);
        const targ_info = await this.get_info(data, abcelem.startChar);

        const phrase_data = document.getElementById("abc-phrase").value;
        const phrase_info = await this.get_info(
          phrase_data,
          phrase_data.length
        );

        await this.phrase_set_info(targ_info, phrase_info);
        this.editingdata =
          document.getElementById("abc-phrase").value + targ_data;
        document.getElementById("editing-alert").innerHTML = "<em>Success</em>";
      } else {
        this.soundFailed();
        document.getElementById("editing-alert").innerHTML =
          "Failed<br>Please select a consecutive note.";
      }
    },
    get_info(abcdata, start) {
      function setting(d) {
        return d.slice(0, d.search(/[\n\]]/));
      }
      let res = new Map();
      const data_slice = abcdata.slice(0, start);
      const mes_slice = data_slice.slice(data_slice.lastIndexOf("M:"));
      res.set("M", setting(mes_slice));
      const len_slice = data_slice.slice(data_slice.lastIndexOf("L:"));
      res.set("L", setting(len_slice));
      const tempo_slice = data_slice.slice(data_slice.lastIndexOf("Q:"));
      res.set("Q", setting(tempo_slice));
      const chord_slice = data_slice.slice(data_slice.lastIndexOf("K:"));
      res.set("K", setting(chord_slice));
      const title_slice = data_slice.slice(data_slice.lastIndexOf("T:"));
      res.set("T", setting(title_slice));
      return res;
    },
    phrase_set_info(targ, dest) {
      const str = document.getElementById("abc-phrase").value;
      if (str.lastIndexOf("\n") !== str.length - 1) {
        for (var [key, val] of targ) {
          if (key !== "T" && val !== dest.get(key))
            document.getElementById("abc-phrase").value +=
              "[" + targ.get(key) + "]";
        }
      } else {
        for (var [key, val] of targ) {
          if (key !== "T" && val !== dest.get(key))
            document.getElementById(
              "abc-phrase"
            ).value = document
              .getElementById("abc-phrase")
              .value.replace(dest.get(key), val);
        }
      }
    },
    clear_phrase() {
      this.soundClear();
      this.editingdata = this.tune;
      this.lastelem = "";
      this.lastscore = "";
    },
    async regist_phrase() {
      this.soundAdd();
      if (document.getElementById("abc-phrase").value !== this.tune) {
        this.old_creation.push(this.creationdata);
        await this.concatenation();
        this.clear_phrase();
      }
    },
    clear_creation() {
      this.soundClear();
      this.editingdata = "";
    },
    undo_creation() {
      this.soundUndo();
      if (this.old_creation.length > 0)
        this.creationdata = this.old_creation.pop();
    },
    async concatenation() {
      const phrase_data = document.getElementById("abc-phrase").value;
      const creation_data = document.getElementById("abc-creation").value;
      const phrase_info = await this.get_info(
        phrase_data,
        phrase_data.indexOf("[")
      );
      const creation_info = await this.get_info(
        creation_data,
        creation_data.length
      );
      if (
        creation_data === "" ||
        creation_data.lastIndexOf(creation_info.get("K")) +
          creation_info.get("K").length +
          1 ===
          creation_data.length
      ) {
        this.creationdata = phrase_data.replace(
          phrase_info.get("T"),
          "T:Music"
        );
      } else {
        await this.creation_set_info(phrase_info, creation_info);
        this.creationdata =
          document.getElementById("abc-creation").value +
          phrase_data.slice(
            phrase_data.indexOf(phrase_info.get("K")) +
              phrase_info.get("K").length +
              1
          );
      }
    },
    creation_set_info(targ, dest) {
      for (const [key, val] of targ) {
        if (key !== "T" && val !== dest.get(key))
          document.getElementById("abc-creation").value +=
            "[" + targ.get(key) + "]";
      }
    },
    leftbutton() {
      this.soundButton();
      if (this.refloc === 0) {
        this.refloc = this.allrefdata.length - 1;
      } else {
        this.refloc--;
      }
      this.abcdata = this.allrefdata[this.refloc];
    },
    rightbutton() {
      this.soundButton();
      if (this.refloc === this.allrefdata.length - 1) {
        this.refloc = 0;
      } else {
        this.refloc++;
      }
      this.abcdata = this.allrefdata[this.refloc];
    },
    async elemContinuty(elem) {
      const func = () => {
        console.log(this.abcdata);
        console.log(this.lastelem);
        console.log(elem.startChar);
        const str = document
          .getElementById("abc-source")
          .value.slice(this.lastelem, elem.startChar);
        console.log(str);
        console.log(str.slice(str.search("]") + 1, str.length));
        return str.search(/([A-Za-z])/);
      };
      if (
        this.lastelem !== "" &&
        (this.lastscore !== this.refloc || this.lastelem > elem.startChar)
      ) {
        return -1;
      } else if (this.lastelem !== "") {
        let res = await func();
        if (res === -1) {
          this.lastelem = elem.endChar;
          this.lastscore = this.refloc;
        }
        if (res === 0) res++;
        return res * -1;
      } else {
        this.lastelem = elem.endChar;
        this.lastscore = this.refloc;
        return 1;
      }
    },
    soundClick() {
      const id = "sound-file-click";
      if (typeof document.getElementById(id).currentTime != "undefined") {
        document.getElementById(id).currentTime = 0;
      }
      document.getElementById(id).play();
    },
    soundClear() {
      const id = "sound-file-clear";
      if (typeof document.getElementById(id).currentTime != "undefined") {
        document.getElementById(id).currentTime = 0;
      }
      document.getElementById(id).play();
    },
    soundAdd() {
      const id = "sound-file-add";
      if (typeof document.getElementById(id).currentTime != "undefined") {
        document.getElementById(id).currentTime = 0;
      }
      document.getElementById(id).play();
    },
    soundUndo() {
      const id = "sound-file-undo";
      if (typeof document.getElementById(id).currentTime != "undefined") {
        document.getElementById(id).currentTime = 0;
      }
      document.getElementById(id).play();
    },
    soundButton() {
      const id = "sound-file-button";
      if (typeof document.getElementById(id).currentTime != "undefined") {
        document.getElementById(id).currentTime = 0;
      }
      document.getElementById(id).play();
    },
    soundFailed() {
      const id = "sound-file-failed";
      if (typeof document.getElementById(id).currentTime != "undefined") {
        document.getElementById(id).currentTime = 0;
      }
      document.getElementById(id).play();
    }
  }
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.hello {
  text-align: left;
}
#abc-source {
  padding: 6px;
  display: none;
}
#abc-phrase {
  padding: 6px;
  display: none;
}
#abc-creation {
  padding: 6px;
  display: none;
}
.container {
  border: solid 1px #000000;
  width: 900px;
  height: 300px;
  overflow: auto;
  box-shadow: 10px 10px 10px rgba(0, 0, 0, 0.4);
}
.music {
  border: solid 1px #000000;
  width: 1200px;
  height: 300px;
  overflow: auto;
  box-shadow: 10px 10px 10px rgba(0, 0, 0, 0.4);
}

.listener-output {
  border: 1px solid #888888;
  padding: 6px;
  border-radius: 4px;
  width: 460px;
  margin-bottom: 20px;
}

.abc-string {
  border: 1px solid #e9ef96;
  padding: 2px;
  height: 24px;
  width: 60px;
  display: inline-block;
  background: #fbf4b8;
}

#midi {
  width: 500px;
}

#midi-phrase {
  width: 500px;
}

#midi-creation {
  width: 500px;
}

#play-info {
  display: none;
}

.label {
  font-weight: bold;
}

.direction {
  height: 50px;
  width: 50px;
}

.modifier {
  height: 20px;
  width: 80px;
}

#creation {
  margin: 30px;
}
#editing {
  margin: 30px;
}
#refer-abc {
  margin: 30px;
}

.note {
  border: 1px solid #e9ef96;
  height: 100px;
  width: 400px;
  color: red;
  background-color: #fbf4b8;
  margin: 3px;
  box-shadow: 3px 3px 3px rgba(0, 0, 0, 0.2);
}
</style>
