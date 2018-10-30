<template>
  <div class="hello">
    <textarea id="abc-source"></textarea>
    <textarea id="abc-phrase" v-model="tune"></textarea>
    <textarea id="abc-creation"></textarea>
    <div class="listener-output">
      <div class="label">Currently Playing: <span class="abc-string">{{currentAbcFragment}}</span></div>

      <div class="label">Parameters sent to listener callback: </div>
      <div>Progress: {{progress.progress }}</div>
      <div>Current Time: {{progress.currentTime }}</div>
      <div>Total Duration: {{progress.duration }}</div>
      <div>New Beat? {{progress.newBeat }}</div>
    </div>
    <div id="midi"></div>
    <div id="midi-download"></div>
    <div id="container">
    <div id="paper"></div>
    </div>
    <div id="midi-phrase"></div>
    <div id="midi-download-phrase"></div>
    <div id="container">
    <div id="paper-phrase"></div>
    </div>
    <button v-on:click="clear_phrase"> clear </button>
    <button v-on:click="regist_phrase"> add </button>
    <div id="midi-creation"></div>
    <div id="midi-download-creation"></div>
    <div id="container">
    <div id="paper-creation"></div>
    </div>
    <button v-on:click="clear_creation"> clear </button>
  </div>
</template>

<script>
import "font-awesome/css/font-awesome.min.css";
import "abcjs/abcjs-midi.css";
import abcjs from "abcjs/midi";

export default {
  mounted: async function() {
    let abcdata = "";
    await fetch("./static/abc/msc-10.abc")
      .then(response => {
        return response.text();
      })
      .then(textdata => {
        abcdata = textdata;
      });
    document.getElementById("abc-source").value = abcdata;
    new abcjs.Editor("abc-source", {
      paper_id: "paper",
      generate_midi: true,
      midi_id: "midi",
      midi_download_id: "midi-download",
      abcjsParams: {
        staffwidth: 700,
        generateDownload: true,
        clickListener: this.selectionCallback,
        midiListener: this.listener,
        animate: {
          listener: this.animate
        }
      }
    });
    new abcjs.Editor("abc-phrase", {
      paper_id: "paper-phrase",
      generate_midi: true,
      midi_id: "midi-phrase",
      midi_download_id: "midi-download-phrase",
      abcjsParams: {
        staffwidth: 700,
        generateDownload: true,
        midiListener: this.listener,
        animate: {
          listener: this.animate
        }
      }
    });
  },
  name: "hello",
  data() {
    return {
      progress: {},
      currentAbcFragment: "(none)",
      tune: "X:1\nT: Editing Phrase\nM: 4/4\nL: 1/8\nQ: 100\nK: C\n"
    };
  },
  methods: {
    listener(midiControl, progress) {
      // This provides a more linear view of the progress, for a progress bar or for an unrelated animation.
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
      var note = {};
      for (var key in abcelem) {
        if (abcelem.hasOwnProperty(key) && key !== "abselem") {
          note[key] = abcelem[key];
        }
      }
      const data = document.getElementById("abc-source").value;
      const targ_data = data.slice(abcelem.startChar, abcelem.endChar);
      const targ_info = await this.get_info(data, abcelem.startChar);
      // console.log(targ_info);

      const phrase_data = document.getElementById("abc-phrase").value;
      const phrase_info = await this.get_info(phrase_data, phrase_data.length);
      // console.log(phrase_info);

      await this.phrase_set_info(targ_info, phrase_info);
      document.getElementById("abc-phrase").value += targ_data;
      // console.log(document.getElementById("abc-phrase").value);

      new abcjs.Editor("abc-phrase", {
        paper_id: "paper-phrase",
        generate_midi: true,
        midi_id: "midi-phrase",
        midi_download_id: "midi-download-phrase",
        abcjsParams: {
          staffwidth: 700,
          generateDownload: true,
          midiListener: this.listener,
          animate: {
            listener: this.animate
          }
        }
      });
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
      return res;
    },
    phrase_set_info(targ, dest) {
      const str = document.getElementById("abc-phrase").value;
      if (str.lastIndexOf("\n") !== str.length - 1) {
        for (var [key, val] of targ) {
          if (val !== dest.get(key))
            document.getElementById("abc-phrase").value +=
              "[" + targ.get(key) + "]";
        }
      } else {
        for (var [key, val] of targ) {
          if (val !== dest.get(key))
            document.getElementById(
              "abc-phrase"
            ).value = document
              .getElementById("abc-phrase")
              .value.replace(dest.get(key), val);
        }
      }
    },
    clear_phrase() {
      document.getElementById("abc-phrase").value = this.tune;
      new abcjs.Editor("abc-phrase", {
        paper_id: "paper-phrase",
        generate_midi: true,
        midi_id: "midi-phrase",
        midi_download_id: "midi-download-phrase",
        abcjsParams: {
          staffwidth: 700,
          generateDownload: true,
          midiListener: this.listener,
          animate: {
            listener: this.animate
          }
        }
      });
    },
    async regist_phrase() {
      await this.concatenation();
      new abcjs.Editor("abc-creation", {
        paper_id: "paper-creation",
        generate_midi: true,
        midi_id: "midi-creation",
        midi_download_id: "midi-download-creation",
        abcjsParams: {
          staffwidth: 700,
          generateDownload: true,
          midiListener: this.listener,
          animate: {
            listener: this.animate
          }
        }
      });
      this.clear_phrase();
    },
    clear_creation() {
      document.getElementById("abc-creation").value = "";
      new abcjs.Editor("abc-creation", {
        paper_id: "paper-creation",
        generate_midi: true,
        midi_id: "midi-creation",
        midi_download_id: "midi-download-creation",
        abcjsParams: {
          staffwidth: 700,
          generateDownload: true,
          midiListener: this.listener,
          animate: {
            listener: this.animate
          }
        }
      });
    },
    async concatenation() {
      const phrase_data = document.getElementById("abc-phrase").value;
      const creation_data = document.getElementById("abc-creation").value;
      if (creation_data === "")
        document.getElementById("abc-creation").value = phrase_data;
      else {
        const phrase_info = await this.get_info(
          phrase_data,
          phrase_data.indexOf("[")
        );
        const creation_info = await this.get_info(
          creation_data,
          creation_data.length
        );
        console.log(phrase_info);
        console.log(creation_info);
        await this.creation_set_info(phrase_info, creation_info);
        document.getElementById("abc-creation").value += phrase_data.slice(
          phrase_data.indexOf(phrase_info.get("K")) +
            phrase_info.get("K").length +
            1
        );
      }
    },
    creation_set_info(targ, dest) {
      for (const [key, val] of targ) {
        if (val !== dest.get(key))
          document.getElementById("abc-creation").value +=
            "[" + targ.get(key) + "]";
      }
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
#container {
  width: 1000px;
  height: auto;
  overflow: auto;
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

pre {
  border: 1px solid #888888;
  padding: 6px;
  border-radius: 4px;
  width: 460px;
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

.label {
  font-weight: bold;
}
</style>
