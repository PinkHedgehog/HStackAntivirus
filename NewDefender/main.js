Vue.config.productionTip = false;
Vue.config.devtools = false;

Vue.filter('kb', val => {
  return Math.floor(val/1024);
});
const app = new Vue({
  el:'#app',
  data: {
    files:[],
    number: 0,
    mail: ''
  },
  computed: {
    uploadDisabled() {
      return this.files.length === 0;
    }
  },
  mounted: function (){

      el = document.getElementById('mail-checkbox')
      el.addEventListener('change', function() {
          ms = document.getElementById('mail-string')
          ms.hidden = !el.checked
      })

  },
  methods:{
    selectFile(){
        fileInput = document.getElementById('file-input');

        while (document.querySelector('.alert')) {
          alert = document.querySelector('.alert')
          alert.remove()
        }

        const img = document.getElementById('tastysweet-2')
        img.src = './pic/Zhelty_povernuty.png'
        const my_sec = document.getElementById('my-security')
        my_sec.textContent = 'Сейчас всё проверим!'
        if (this.number > 0) return;

        fileInput.addEventListener('change', function() {
            var file = fileInput.files[0];
            this.files.push(file)
            this.number++;
            this.getImagePreviews();
            //var reader = new FileReader();
            //reader.readAsDataURL(file);

        }.bind(this), false);//.bind(this);

        fileInput.click();
        scanfile = document.getElementById('scanfile');
        scanfile.hidden = false;
        //this.files.push(f);

    },

    getImagePreviews() {
      for (let i = 0; i < this.files.length; i++) {
        if ( /\.(jpe?g|png|gif)$/i.test(this.files[i].name)) {
          let reader = new FileReader();
            reader.addEventListener("load", function() {
                this.$refs['preview' + parseInt(i)][0].src = reader.result;
            }.bind(this), false);

            reader.readAsDataURL(this.files[i]);
        } else {


          this.$nextTick(() => {
            this.$refs['preview' + parseInt(i)][0].hidden = true;
          });
        }
      }
    },


    addFile(e) {
      while (document.querySelector('.alert')) {
        alert = document.querySelector('.alert')
        alert.remove()
      }

      const img = document.getElementById('tastysweet-2')
      img.src = './pic/Zhelty_povernuty.png'
      const my_sec = document.getElementById('my-security')
      my_sec.textContent = 'Сейчас всё проверим!'
      if (this.number > 0) return;
      let droppedFiles = e.dataTransfer.files;
      // if(!droppedFiles) {
      //     const ordinary_input = document.getElementById('input-1')
      //     if
      // }
      ([...droppedFiles]).forEach(f => {
        this.files.push(f);
        this.number++;
        this.getImagePreviews();
      });
      scanfile = document.getElementById('scanfile');
      scanfile.hidden = false;
    },
    removeFile(file){
      while (document.querySelector('.alert')) {
        alert = document.querySelector('.alert')
        alert.remove()
      }
      img = document.getElementById('tastysweet-2');
      img.src = './pic/leaf.png';
      scanfile = document.getElementById('scanfile');
      scanfile.hidden = true;
      const my_sec = document.getElementById('my-security')
      my_sec.textContent = 'Ты в безопасности!'
      if (this.number > 0) {
          this.files = this.files.filter(f => {
            this.number--;
            return f != file;
          });
      }
    },


    upload() {
        const showAlert = (message, className) => {
            const div = document.createElement('div')
            div.className = `alert alert-${className}`
            div.appendChild(document.createTextNode(message))
            const container = document.getElementById('tastysweet-1')
            console.log('container: ' + container)
            const form = document.getElementById('tastysweet-2')
            console.log('form: ' + form)
            container.insertBefore(div, form)
            setTimeout(() => {
                document.querySelector('.alert').remove()
                img = document.getElementById('tastysweet-2')
                img.src = './pic/leaf.png'
            }, 15000)
        }

        mail_cb = document.getElementById('mail-checkbox')
        if (mail_cb.value) {
            mail_string = document.getElementById('mail-string')
            mail_string.hidden = false;
            this.mail = mail_string.value;
            console.log(this.mail)
        }

        let formData = new FormData();
        this.files.forEach((f,x) => {
        formData.append('files', f);
        console.log(f)
        });
        console.log(this.mail)
        formData.append('mail', this.mail)
        console.log(formData)

/* АХТУНГ!
После переноса бэка на постоянный хостинг надо будет заменить http://localhost:8000 на актуальный URL!
*/
      //fetch('http://46.101.136.70', {method:'POST', headers: {}, body: formData})
      fetch('http://localhost:8000/files', {method:'POST', headers: {}, body: formData})
        .then(async res => {
          res.headers.forEach(console.log);
          const ts = document.getElementById('tastysweet')
          const reader = res.body.getReader();

          // бесконечный цикл, пока идёт загрузка
          var arr = []
          while(true) {
            // done становится true в последнем фрагменте
            // value - Uint8Array из байтов каждого фрагмента
            const {done, value} = await reader.read();

            if (done) {
              break;
            }

            arr = value
            console.log(`Получено ${value} байт`)
          }
          var str='';
          for (i in arr){
              str+=String.fromCharCode(arr[i]);
          }
          console.log(str);

          var parser = new DOMParser();
          var htmlDoc = parser.parseFromString(str, 'text/html');

          const p_result = htmlDoc.getElementsByClassName('checking-result')[0]

          if (p_result.id == 'ok') {
            img = document.getElementById('tastysweet-2')
            img.src = './pic/leaf.png'
            const my_sec = document.getElementById('my-security')
            my_sec.textContent = 'Ты в безопасности!'
            showAlert('Everything is OK!', 'success', this)
          } else {
            img = document.getElementById('tastysweet-2')
            img.src = './pic/listbezkaplikras.png'
            const my_sec = document.getElementById('my-security')
            my_sec.textContent = 'Безопасность под угрозой!'
            showAlert('Danger found: ' + p_result.textContent, 'danger', this)
          }

          console.log('done uploading', res);
          res;
        }).catch(e => {
            console.log(e);
            console.error(JSON.stringify(e.message));
        });

    },
  }
})
