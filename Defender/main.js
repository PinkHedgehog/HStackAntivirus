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
  created: function() {
      el2 = document.getElementById('mail-string')
      el2.addEventListener('keypress', (event) => {
          const keyname = event.key
          if (keyname == 'Enter') {
              console.log("e.keyCode == 13");
              event.preventDefault()
              this.upload()
              return false;
          } else {
              return true;
          }
      })
  },
  mounted: function (){

      el = document.getElementById('mail-checkbox')
      el.addEventListener('change', function() {
          ms = document.getElementById('mail-string')
          ms.hidden = !el.checked
          ms.value = ''
      })

      el2 = document.getElementById('mail-string')
      el2.addEventListener('keypress', (event) => {
          const keyname = event.key
          if (keyname == 'Enter') {
              console.log("e.keyCode == 13");
              event.preventDefault()
              this.upload()
              return false;
          } else {
              return true;
          }
      })

  },
  methods:{
    selectFile(){
        if (this.number > 0) return;
        fileInput = document.getElementById('file-input');

        while (document.querySelector('.alert')) {
          alert = document.querySelector('.alert')
          alert.remove()
        }

        const img = document.getElementById('tastysweet-2')
        img.src = './pic/Zhelty_povernuty.png'
        const my_sec = document.getElementById('my-security')
        my_sec.textContent = 'Сейчас всё проверим!'


        fileInput.addEventListener('change', function() {
            if (this.files.length == 0) {
                var file = fileInput.files[0];
                this.files.push(file);
                this.number = 1;
                fileInput.value = null;
                this.getImagePreviews();
            } else {
                return;
            }

        }.bind(this), false);//.bind(this);

        fileInput.click();
        scanfile = document.getElementById('scanfile');
        scanfile.hidden = false;
        const hashfile = document.getElementById('shHash');
        hashfile.hidden = false;
        //this.files.push(f);

    },
    showAlert(message, className) {
        const div = document.createElement('div')
        div.className = `alert alert-${className}`
        div.appendChild(document.createTextNode(message))
        const container = document.getElementById('tastysweet-1')
        console.log('container: ' + container)
        const form = document.getElementById('tastysweet-2')
        console.log('form: ' + form)
        container.insertBefore(div, form)
        setTimeout(() => {
            if (document.querySelector('.alert') != null) {
                document.querySelector('.alert').remove()
            }
            img = document.getElementById('tastysweet-2')
            img.src = './pic/leaf.png'
        }, 15000)
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

    hashFile() {
        if (this.files.length < 1) return;
        const filename = this.files[0].name
        const showHash = (hash) => this.showAlert(filename + ' SHA256: ' + hash, 'info')
        var reader = new FileReader();
        reader.onload = function( e ){
            var hash = CryptoJS.SHA256(e.target.result).toString();
            showHash(hash)
        }
        reader.readAsBinaryString(this.files[0]);
    }, //.bind(this)

    addFile(e) {
      while (document.querySelector('.alert')) {
        alert = document.querySelector('.alert')
        alert.remove()
      }
      if (this.number > 0) return;
      const img = document.getElementById('tastysweet-2')
      img.src = './pic/Zhelty_povernuty.png'
      const my_sec = document.getElementById('my-security')
      my_sec.textContent = 'Сейчас всё проверим!'

      let droppedFiles = e.dataTransfer.files;

      console.log(([...droppedFiles]).length);
      ([...droppedFiles]).forEach(f => {
        this.files.push(f);
        this.number++;
        this.getImagePreviews();
      });
      scanfile = document.getElementById('scanfile');
      scanfile.hidden = false;
      const hashfile = document.getElementById('shHash');
      hashfile.hidden = false;

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
      hashfile = document.getElementById('shHash');
      hashfile.hidden = true;
      const my_sec = document.getElementById('my-security')
      my_sec.textContent = 'Ты в безопасности!'
      if (this.number > 0) {
          this.files = []
          this.number--;
      }
    },


    upload() {
	    if (al = document.querySelector('.alert')) al.remove();
        this.hashFile()
        if (this.files.length == 0) return;
        for (k in Object.keys(this.files[0])) {
            console.log('Key: ' + k)
        }
        mail_cb = document.getElementById('mail-checkbox')
        if (mail_cb.checked) {
            mail_string = document.getElementById('mail-string')
            this.mail = mail_string.value;
            mail_string.hidden = mail_cb.checked;
            mail_cb.checked = false;
            mail_string = '';
	        var emailPattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;
            if (!emailPattern.test(this.mail)) {
                this.mail = '';
                this.showAlert('Incorrect email', 'info');
                return;
            }
        } else {
	        this.mail = '';
        }

        let formData = new FormData();
        this.files.forEach((f,x) => {
        formData.append('files', f);
        console.log(f)
        });
        console.log(this.mail)
        formData.append('mail', this.mail)
        console.log(formData)
        const filename = this.files[0].name;

      //fetch('https://localhost:8443', {method:'POST', headers: {}, body: formData})
      fetch('https://defendercode.xyz', {method:'POST', headers: {}, body: formData})
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

            arr = value;
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
            this.showAlert('Everything is OK!', 'success')
          } else {
            img = document.getElementById('tastysweet-2')
            img.src = './pic/listbezkaplikras.png'
            const my_sec = document.getElementById('my-security')
            my_sec.textContent = 'Безопасность под угрозой!'
            this.showAlert('Danger found: ' + p_result.textContent, 'danger')
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
