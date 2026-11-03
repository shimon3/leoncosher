let healthMode='web';
function setHealthMode(mode){healthMode=mode;render()}
function pdfDemo(event){event.preventDefault();const f=event.target;const file=f.querySelector('input[type=file]').files[0];if(!file)return; if(file.type!=='application/pdf'){alert('PDF בלבד / Только PDF');return;}const note=document.getElementById('pdf-demo-result');note.textContent=(lang==='he'?'קובץ נבחר: ':'Выбран файл: ')+file.name+(lang==='he'?' — הדגמה בלבד, לא הועלה ולא נשלח.':' — демонстрация, файл не загружен и не отправлен.');}
