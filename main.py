import os
import re
import csv
import json
import threading
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from datetime import datetime
from ollama import chat

LLM_MODEL = "qwen2.5:7b"

class MeetingApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Meeting AI - Анализ задач из совещаний")
        self.root.geometry("900x800")
        self.root.configure(bg='#f0f0f0')
        
        self.audio_path = None
        self.last_folder = None
        
        self.create_widgets()
    
    def create_widgets(self):
        # Заголовок
        title_frame = tk.Frame(self.root, bg='#f0f0f0')
        title_frame.pack(pady=15)
        
        title = tk.Label(title_frame, text="️ Meeting AI", font=("Segoe UI", 24, "bold"), bg='#f0f0f0')
        title.pack()
        
        subtitle = tk.Label(title_frame, text="Автоматическое извлечение задач из записей совещаний", 
                           font=("Segoe UI", 10), bg='#f0f0f0', fg='gray')
        subtitle.pack()
        
        # Выбор модели
        model_frame = tk.Frame(self.root, bg='#f0f0f0')
        model_frame.pack(pady=5)
        
        tk.Label(model_frame, text="Модель:", font=("Segoe UI", 9), bg='#f0f0f0').pack(side=tk.LEFT, padx=5)
        self.model_var = tk.StringVar(value=LLM_MODEL)
        model_combo = ttk.Combobox(model_frame, textvariable=self.model_var, width=20, state="readonly")
        model_combo['values'] = ('qwen2.5:7b', 'qwen2.5:3b', 'llama3.1:8b', 'mistral:7b')
        model_combo.pack(side=tk.LEFT, padx=5)
        
        # Выбор файла
        file_frame = tk.LabelFrame(self.root, text="1. Выберите аудиофайл", font=("Segoe UI", 11, "bold"), 
                                   padx=15, pady=15, bg='white')
        file_frame.pack(padx=15, pady=10, fill="x")
        
        self.file_label = tk.Label(file_frame, text="Файл не выбран", fg="gray", font=("Segoe UI", 9), bg='white')
        self.file_label.pack(pady=5)
        
        btn_select = tk.Button(file_frame, text="📂 Выбрать файл", command=self.select_file, 
                              width=25, bg='#e1e1e1', font=("Segoe UI", 9))
        btn_select.pack(pady=5)
        
        # Поле для текста
        text_frame = tk.LabelFrame(self.root, text="2. Или вставьте текст расшифровки", 
                                   font=("Segoe UI", 11, "bold"), padx=15, pady=15, bg='white')
        text_frame.pack(padx=15, pady=10, fill="both", expand=True)
        
        self.text_area = tk.Text(text_frame, height=10, font=("Consolas", 10), wrap=tk.WORD, 
                                bg='white', relief=tk.SOLID, borderwidth=1)
        self.text_area.pack(fill="both", expand=True, pady=5)
        
        scrollbar = tk.Scrollbar(text_frame, orient=tk.VERTICAL, command=self.text_area.yview)
        self.text_area.configure(yscrollcommand=scrollbar.set)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Контекстное меню
        self.context_menu = tk.Menu(self.root, tearoff=0)
        self.context_menu.add_command(label="✂️ Вырезать", command=lambda: self.text_area.event_generate("<<Cut>>"))
        self.context_menu.add_command(label="📋 Копировать", command=lambda: self.text_area.event_generate("<<Copy>>"))
        self.context_menu.add_command(label=" Вставить", command=self.paste_from_menu)
        self.context_menu.add_separator()
        self.context_menu.add_command(label="🗑️ Удалить всё", command=self.clear_text)
        
        self.text_area.bind("<Button-3>", self.show_context_menu)
        self.text_area.bind("<Control-V>", self.paste_text)
        self.text_area.bind("<Control-v>", self.paste_text)
        self.text_area.bind("<Control-A>", self.select_all)
        self.text_area.bind("<Control-a>", self.select_all)
        
        # Кнопки управления текстом
        btn_frame = tk.Frame(text_frame, bg='white')
        btn_frame.pack(pady=5)
        
        btn_test = tk.Button(btn_frame, text=" Загрузить тестовый текст", command=self.load_test_text, 
                            width=25, bg='#e3f2fd', font=("Segoe UI", 9))
        btn_test.pack(side=tk.LEFT, padx=5)
        
        btn_paste = tk.Button(btn_frame, text="📥 Вставить из буфера", command=self.paste_from_button, 
                             width=20, bg='#e8f5e9', font=("Segoe UI", 9))
        btn_paste.pack(side=tk.LEFT, padx=5)
        
        btn_clear = tk.Button(btn_frame, text="🗑️ Очистить", command=self.clear_text, 
                             width=15, bg='#ffebee', font=("Segoe UI", 9))
        btn_clear.pack(side=tk.LEFT, padx=5)
        
        # Кнопка запуска
        btn_start = tk.Button(self.root, text="▶️ НАЧАТЬ ОБРАБОТКУ", command=self.start_processing, 
                             font=("Segoe UI", 14, "bold"), bg='#4CAF50', fg='white', 
                             padx=30, pady=15, relief=tk.RAISED, borderwidth=3)
        btn_start.pack(pady=15)
        
        # Прогресс-бар
        self.progress_var = tk.DoubleVar(value=0)
        self.progress_bar = ttk.Progressbar(self.root, variable=self.progress_var, maximum=100)
        self.progress_bar.pack(padx=20, fill=tk.X, pady=5)
        
        self.status_label = tk.Label(self.root, text="Готов к работе", font=("Segoe UI", 11), 
                                    bg='#f0f0f0', fg='blue')
        self.status_label.pack(pady=5)
        
        # Лог
        log_frame = tk.LabelFrame(self.root, text="Лог работы", font=("Segoe UI", 10, "bold"), 
                                 padx=10, pady=10, bg='white')
        log_frame.pack(padx=15, pady=10, fill="both", expand=True)
        
        self.log_area = tk.Text(log_frame, height=5, font=("Consolas", 9), state=tk.DISABLED, 
                               bg='#f5f5f5', relief=tk.SOLID, borderwidth=1)
        self.log_area.pack(fill="both", expand=True)
        
        # Кнопки результатов
        self.result_frame = tk.Frame(self.root, bg='#f0f0f0')
        self.result_frame.pack(pady=10)
        
        self.btn_folder = tk.Button(self.result_frame, text="📁 Открыть папку", command=self.open_folder, 
                                   state=tk.DISABLED, width=18)
        self.btn_folder.pack(side=tk.LEFT, padx=5)
        
        self.btn_csv = tk.Button(self.result_frame, text="📊 Открыть CSV", command=self.open_csv, 
                                state=tk.DISABLED, width=18)
        self.btn_csv.pack(side=tk.LEFT, padx=5)
        
        self.btn_transcript = tk.Button(self.result_frame, text="💬 Расшифровка", command=self.open_transcript, 
                                       state=tk.DISABLED, width=18)
        self.btn_transcript.pack(side=tk.LEFT, padx=5)
        
        self.log("✅ Приложение готово. Выберите файл или вставьте текст.")
    
    def show_context_menu(self, event):
        try:
            self.context_menu.tk_popup(event.x_root, event.y_root)
        finally:
            self.context_menu.grab_release()
    
    def paste_from_menu(self):
        try:
            text = self.root.clipboard_get()
            self.text_area.insert(tk.INSERT, text)
            self.log("📥 Текст вставлен из буфера обмена")
        except tk.TclError as e:
            messagebox.showwarning("Буфер обмена", f"Не удалось вставить текст:\n{e}")
    
    def paste_from_button(self):
        try:
            text = self.root.clipboard_get()
            if text:
                self.text_area.insert(tk.END, "\n" + text if self.text_area.get(1.0, tk.END).strip() else text)
                self.log("📥 Текст вставлен из буфера обмена")
            else:
                messagebox.showinfo("Буфер обмена", "Буфер обмена пуст!")
        except tk.TclError:
            messagebox.showwarning("Ошибка", "Не удалось получить доступ к буферу обмена")
    
    def paste_text(self, event=None):
        try:
            text = self.root.clipboard_get()
            self.text_area.insert(tk.INSERT, text)
            return 'break'
        except tk.TclError:
            pass
        return 'break'
    
    def select_all(self, event=None):
        self.text_area.tag_add(tk.SEL, "1.0", tk.END)
        self.text_area.mark_set(tk.INSERT, "1.0")
        self.text_area.see(tk.INSERT)
        return 'break'
    
    def clear_text(self):
        if messagebox.askyesno("Подтверждение", "Очистить текстовое поле?"):
            self.text_area.delete(1.0, tk.END)
            self.log("️ Поле очищено")
    
    def log(self, message):
        self.log_area.config(state=tk.NORMAL)
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.log_area.insert(tk.END, f"[{timestamp}] {message}\n")
        self.log_area.see(tk.END)
        self.log_area.config(state=tk.DISABLED)
    
    def update_progress(self, value, status=""):
        self.progress_var.set(value)
        if status:
            self.status_label.config(text=status)
        self.root.update_idletasks()
    
    def select_file(self):
        filetypes = [
            ("Аудио файлы", "*.mp3 *.wav *.m4a *.flac *.ogg"),
            ("Все файлы", "*.*")
        ]
        path = filedialog.askopenfilename(title="Выберите аудиофайл", filetypes=filetypes)
        if path:
            self.audio_path = path
            size_mb = os.path.getsize(path) / (1024 * 1024)
            self.file_label.config(text=f"{os.path.basename(path)} ({size_mb:.2f} MB)", fg="black")
            self.log(f"📁 Выбран файл: {os.path.basename(path)}")
    
    def load_test_text(self):
        test_text = """Алексей: Так, коллеги, давайте быстро пробежимся по текущим вопросам. Мария, что у нас с презентацией для инвесторов?

Мария: Ну, в целом почти всё готово, но я жду от Дмитрия свежие цифры по бюджету. Без них не могу закончить слайды с финансовыми показателями.

Дмитрий: Да, я помню. Слушайте, я вчера общался с бухгалтерией, они говорят, что полный отчёт будет только в четверг. 

Алексей: Хм, а раньше никак? У нас же встреча в четверг утром.

Дмитрий: Я попробую выбить у них хотя бы предварительные данные завтра-послезавтра.

Алексей: Хорошо, давай так. Если не получится получить полные цифры, сделай хотя бы примерные расчёты, чтобы Мария могла работать. 

Мария: Да, хоть какие-то цифры, я тогда хотя бы структуру слайдов подготовлю.

Алексей: Отлично. Ещё вопрос - кто-нибудь связывался с типографией насчёт раздаточных материалов?

Сергей: Я как раз собирался этим заняться. Нужно же 200 экземпляров, правильно?

Алексей: Да, именно. Сергей, свяжись с несколькими типографиями, сравни цены. У нас же есть стандартные требования к качеству?

Сергей: Да, я помню. Думаю, дня три понадобится, чтобы получить коммерческие предложения и выбрать оптимальный вариант.

Алексей: Хорошо, только не затягивай. Анна, ты сможешь помочь Сергею, если что?

Анна: Конечно, без проблем.

Алексей: Теперь по технической части. Иван, как там с загрузкой на продакшн? Всё ещё есть проблемы?

Иван: Да, не без этого. Когда мы проводили нагрузочное тестирование, сервер начал падать при пиковых нагрузках. Нужно что-то делать с базой данных.

Алексей: Сколько времени понадобится на решение?

Иван: Честно говоря, недели две, наверное. Нужно проанализировать, оптимизировать запросы, возможно, индексы добавить.

Алексей: Две недели... У нас же релиз через три недели. Успеваем, но впритык. Иван, может, возьмёшь кого-то в помощь?

Иван: Да, я думал об этом. Пётр как раз освободился после завершения проекта с CRM.

Алексей: Отлично, подключай Петра. И вот что ещё - подготовь, пожалуйста, краткий отчёт для руководства, почему у нас возникли эти проблемы с сервером. Чтобы на следующем совете директоров могли обсудить.

Иван: Хорошо, сделаю. Думаю, к пятнице успею подготовить.

Алексей: Супер. Ольга, как там с документацией для пользователей?

Ольга: Честно говоря, там нужно многое обновить. Скриншоты устарели, некоторые функции изменились. 

Алексей: Сможешь взяться за это?

Ольга: Да, конечно. Только мне нужен будет доступ к новой версии продукта, чтобы сделать актуальные скриншоты.

Алексей: Иван, дай Ольге доступ к тестовому стенду, хорошо?

Иван: Без проблем, сегодня же сделаю.

Ольга: Отлично, тогда я приступлю в понедельник. Когда нужен результат?

Алексей: Давай ориентируйся на дату релиза - через три недели. Если успеешь раньше - вообще замечательно.

Ольга: Постараюсь.

Алексей: И последнее - Наталья, ты занимаешься организацией корпоратива в пятницу?

Наталья: Да, Алексей. Нужно заказать транспорт, забронировать столы в ресторане.

Алексей: Сколько человек планируется?

Наталья: Примерно человек 15-20. Я сейчас собираю подтверждения от сотрудников.

Алексей: Хорошо. Закажи микроавтобус, чтобы всем хватило мест. И не забудь согласовать бюджет с бухгалтерией.

Наталья: Конечно. Думаю, тысяч 15-20 понадобится на транспорт.

Алексей: Нормально. Только отчёт потом предоставишь, как обычно.

Наталья: Обязательно.

Алексей: Всё, вроде всё обсудили. Кто-то ещё хочет что-то добавить?

Мария: Алексей, а когда мы соберёмся ещё раз, чтобы обсудить прогресс?

Алексей: Давайте в среду, в это же время. К тому времени у Дмитрия будут цифры, Сергей свяжется с типографиями, Иван с Петром начнут работу над базой.

Иван: Договорились.

Алексей: Отлично. Тогда всем спасибо, до среды!"""
        
        self.text_area.delete(1.0, tk.END)
        self.text_area.insert(1.0, test_text)
        self.log("📋 Загружен тестовый текст совещания")
    
    def start_processing(self):
        has_audio = self.audio_path is not None
        has_text = len(self.text_area.get(1.0, tk.END).strip()) > 50
        
        if not has_audio and not has_text:
            messagebox.showwarning("Внимание", "Выберите аудиофайл ИЛИ вставьте текст совещания!")
            return
        
        if has_audio and has_text:
            if not messagebox.askyesno("Подтверждение", "Найдены и файл, и текст. Обработать текст из поля?"):
                self.audio_path = None
                self.file_label.config(text="Используем текст", fg="blue")
        
        thread = threading.Thread(target=self.process, daemon=True)
        thread.start()
    
    def process(self):
        try:
            text = ""
            mode = "text" if len(self.text_area.get(1.0, tk.END).strip()) > 50 else "audio"
            
            if mode == "audio":
                self.update_progress(5, "🎙️ Транскрибирую аудио...")
                self.log("Начинаю транскрибацию аудио...")
                
                from faster_whisper import WhisperModel
                model = WhisperModel("tiny", device="cpu", compute_type="int8", cpu_threads=4)
                segments, info = model.transcribe(self.audio_path, language="ru", beam_size=1, vad_filter=True)
                
                for segment in segments:
                    text += segment.text + " "
                
                self.update_progress(30, f"✅ Транскрибация завершена. {len(text)} символов.")
                self.log(f"✅ Транскрибация завершена. {len(text)} символов.")
            else:
                text = self.text_area.get(1.0, tk.END).strip()
                self.update_progress(30, f"📝 Текст готов ({len(text)} символов)")
                self.log(f"📝 Использую текст ({len(text)} символов)")
            
            self.update_progress(40, "🤖 Анализирую через нейросеть...")
            self.log("🤖 Отправляю текст в нейросеть для анализа...")
            
            tasks = self.extract_tasks(text)
            
            self.update_progress(90, f"✅ Найдено задач: {len(tasks)}")
            self.log(f"✅ Найдено задач: {len(tasks)}")
            
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            base_name = os.path.splitext(os.path.basename(self.audio_path))[0] if mode == "audio" else "meeting_text"
            
            folder_name = f"{base_name}_{timestamp}"
            folder_path = os.path.join(".", folder_name)
            os.makedirs(folder_path, exist_ok=True)
            
            self.save_results(folder_path, text, tasks)
            
            self.last_folder = folder_path
            self.update_progress(100, f"✅ Готово! Найдено {len(tasks)} задач")
            self.log(f"📁 Результаты сохранены в: {folder_name}")
            
            self.btn_folder.config(state=tk.NORMAL)
            self.btn_csv.config(state=tk.NORMAL)
            self.btn_transcript.config(state=tk.NORMAL)
            
            messagebox.showinfo("Готово!", f"Обработка завершена!\n\nНайдено задач: {len(tasks)}\n\nРезультаты сохранены в папку: {folder_name}")
            
        except Exception as e:
            self.update_progress(0, "❌ Ошибка!")
            self.log(f"❌ ОШИБКА: {str(e)}")
            messagebox.showerror("Ошибка", f"Произошла ошибка:\n{str(e)}")
    
    def extract_tasks(self, text):
        """Извлекает задачи из текста совещания с помощью LLM"""
        
        prompt = f"""Ты — эксперт по анализу деловых совещаний. Твоя задача — найти ВСЕ задачи, поручения и договорённости в стенограмме.

СТЕНОГРАММА СОВЕЩАНИЯ:
{text}

ИНСТРУКЦИИ ПО ПОИСКУ ЗАДАЧ:

1. Ищи ВСЕ типы задач:
   ✓ Прямые поручения: "Иван, сделай отчёт", "Мария, подготовь презентацию"
   ✓ Косвенные указания: "нужно подготовить", "следует связаться"
   ✓ Договорённости: "договорились встретиться", "я займусь этим"
   ✓ Планы и обещания: "я подготовлю к пятнице", "мы сделаем на следующей неделе"
   ✓ Просьбы: "дай доступ", "помоги Сергею", "свяжись с ними"
   ✓ Вопросы с подразумеваемым действием: "кто займётся?", "когда будет готово?"

2. Ключевые слова для поиска:
   - Глаголы: сделай, подготовь, свяжись, закажи, дай, подключай, возьми, займись, организуй, согласуй, найди, сравни, выбери
   - Модальные: нужно, необходимо, следует, надо, должен
   - Временные: до пятницы, к среде, на следующей неделе, сегодня, завтра, в понедельник

3. Для каждой задачи определи:
   - task: ЧТО конкретно нужно сделать (начни с глагола)
   - assignee: КТО должен выполнить (имя человека, если не указано — "Не назначен")
   - deadline: КОГДА нужно выполнить (конкретная дата, относительный срок, или "Не указан")
   - priority: Приоритет на основе контекста:
     • Высокий — если есть слова "срочно", "критично", "максимальный", "как можно скорее"
     • Средний — если есть "не затягивай", "впритык", "успеваем но", обычные рабочие задачи
     • Низкий — если нет срочности, "когда будет время", "не срочно"

4. ВАЖНО:
   - Не пропускай НИ ОДНУ задачу, даже если она упоминается вскользь
   - Если одна задача упоминается несколько раз — объедини в одну
   - Если задача разбивается на подзадачи — создай отдельные записи
   - Будь внимателен к контексту: "я сделаю" = задача для говорящего

ВЕРНИ ВСЕ НАЙДЕННЫЕ ЗАДАЧИ в формате JSON-массива:
[
  {{"task": "Подготовить отчёт по продажам", "assignee": "Иванов", "deadline": "до пятницы", "priority": "Высокий"}},
  {{"task": "Связаться с типографией", "assignee": "Сергей", "deadline": "3 дня", "priority": "Средний"}}
]

Если задач нет, верни пустой массив []."""

        try:
            model = self.model_var.get()
            self.log(f"🤖 Используем модель: {model}")
            
            response = chat(
                model=model,
                messages=[{"role": "user", "content": prompt}],
                format="json",
                options={
                    "temperature": 0.3,
                    "num_predict": 3000  # Увеличиваем лимит для большего количества задач
                }
            )
            
            raw = response.message.content.strip()
            raw = raw.replace("```json", "").replace("```", "").strip()
            
            # Ищем JSON-массив
            match = re.search(r'\[[\s\S]*\]', raw)
            if match:
                raw = match.group(0)
            
            tasks = json.loads(raw)
            
            # Нормализация
            normalized = []
            for t in tasks:
                if isinstance(t, dict):
                    task_text = t.get("task", "").strip()
                    if task_text:  # Пропускаем пустые задачи
                        normalized.append({
                            "task": task_text,
                            "assignee": t.get("assignee", "Не назначен").strip() or "Не назначен",
                            "deadline": t.get("deadline", "Не указан").strip() or "Не указан",
                            "priority": t.get("priority", "Средний").strip() or "Средний"
                        })
            
            self.log(f"✅ Извлечено {len(normalized)} задач")
            return normalized
            
        except Exception as e:
            self.log(f"❌ Ошибка извлечения задач: {e}")
            return []
    
    def save_results(self, folder_path, text, tasks):
        # transcript.txt
        with open(os.path.join(folder_path, "transcript.txt"), "w", encoding="utf-8") as f:
            f.write(text)
        
        # tasks.json
        with open(os.path.join(folder_path, "tasks.json"), "w", encoding="utf-8") as f:
            json.dump(tasks, f, ensure_ascii=False, indent=2)
        
        # tasks.csv
        with open(os.path.join(folder_path, "tasks.csv"), "w", encoding="utf-8-sig", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=['№', 'Задача', 'Ответственный', 'Срок', 'Приоритет'], delimiter=';')
            writer.writeheader()
            for i, task in enumerate(tasks, 1):
                writer.writerow({
                    '№': i,
                    'Задача': task.get('task', ''),
                    'Ответственный': task.get('assignee', ''),
                    'Срок': task.get('deadline', ''),
                    'Приоритет': task.get('priority', '')
                })
        
        # tasks.md
        with open(os.path.join(folder_path, "tasks.md"), "w", encoding="utf-8") as f:
            f.write(f"# Задачи по совещанию\n\n")
            f.write(f"*Дата обработки: {datetime.now().strftime('%d.%m.%Y %H:%M')}*\n\n")
            
            if tasks:
                f.write(f"**Всего задач: {len(tasks)}**\n\n")
                f.write("| № | Задача | Ответственный | Срок | Приоритет |\n")
                f.write("|---|--------|---------------|------|-----------|\n")
                for i, task in enumerate(tasks, 1):
                    priority_emoji = {"Высокий": "🔴", "Средний": "", "Низкий": "🟢"}.get(task.get('priority', ''), '⚪')
                    f.write(f"| {i} | {task.get('task', '')} | {task.get('assignee', '')} | {task.get('deadline', '')} | {priority_emoji} {task.get('priority', '')} |\n")
            else:
                f.write("*Задач не найдено*\n")
        
        # summary.txt - краткая сводка
        with open(os.path.join(folder_path, "summary.txt"), "w", encoding="utf-8") as f:
            f.write("="*60 + "\n")
            f.write("КРАТКАЯ СВОДКА ПО СОВЕЩАНИЮ\n")
            f.write("="*60 + "\n\n")
            f.write(f"Дата обработки: {datetime.now().strftime('%d.%m.%Y %H:%M')}\n")
            f.write(f"Всего задач: {len(tasks)}\n\n")
            
            if tasks:
                f.write("СПИСОК ЗАДАЧ:\n")
                f.write("-"*60 + "\n")
                for i, task in enumerate(tasks, 1):
                    f.write(f"{i}. {task.get('task', '')}\n")
                    f.write(f"   Ответственный: {task.get('assignee', '')}\n")
                    f.write(f"   Срок: {task.get('deadline', '')}\n")
                    f.write(f"   Приоритет: {task.get('priority', '')}\n\n")
            else:
                f.write("Задач не найдено.\n")
        
        self.log("💾 Сохранены файлы: transcript.txt, tasks.json, tasks.csv, tasks.md, summary.txt")
    
    def open_folder(self):
        if self.last_folder:
            os.startfile(self.last_folder)
    
    def open_csv(self):
        if self.last_folder:
            csv_path = os.path.join(self.last_folder, "tasks.csv")
            if os.path.exists(csv_path):
                os.startfile(csv_path)
    
    def open_transcript(self):
        if self.last_folder:
            transcript_path = os.path.join(self.last_folder, "transcript.txt")
            if os.path.exists(transcript_path):
                os.startfile(transcript_path)

if __name__ == "__main__":
    root = tk.Tk()
    app = MeetingApp(root)
    root.mainloop()