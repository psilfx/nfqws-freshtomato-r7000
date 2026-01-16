class AdminPanel {
	constructor() {
		this.originalContent = {
			file1: '',
			file2: ''
		};
		this.currentContent = {
			file1: '',
			file2: ''
		};
		this.Init();
	}
	Init() {
		this.BindEvents();
		this.LoadFiles();
	}
	BindEvents() {
		// Кнопки управления приложением
		document.getElementById('btnStart').addEventListener(   'click', () => this.ControlApp( 'start' ) );
		document.getElementById('btnStop').addEventListener(    'click', () => this.ControlApp( 'stop' ) );
		document.getElementById('btnRestart').addEventListener( 'click', () => this.ControlApp( 'restart' ) );
		// Кнопка сохранения
		document.getElementById('btnSaveAll').addEventListener('click', () => this.SaveAllFiles());
		// Отслеживание изменений в текстовых полях
		document.getElementById('file1').addEventListener('input', (e) => {
			this.currentContent.file1 = e.target.value;
		});
		document.getElementById('file2').addEventListener('input', (e) => {
			this.currentContent.file2 = e.target.value;
		});
		// Автосохранение по Ctrl+S
		document.addEventListener('keydown', (e) => {
			if ((e.ctrlKey || e.metaKey) && e.key === 's') {
				e.preventDefault();
				this.SaveAllFiles();
			}
		});
	}
	async SendRequest( command ) {
		const response = await fetch( '/zapret_ctl.php' , {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
			},
			body: JSON.stringify({
				command: command,
				timeout: 300 // 5 минут
			})
		});
		return response.json();
	}
	async GetFileContent( file ) {
		const response = await fetch( '/zapret_file_read.php' , {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
			},
			body: JSON.stringify({
				file: file,
				timeout: 300 // 5 минут
			})
		});
		return response.text();
	}
	async WriteFileContent( file , content ) {
		const response = await fetch( '/zapret_file_write.php' , {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
			},
			body: JSON.stringify({
				file: file,
				content: content,
				timeout: 300 // 5 минут
			})
		});
	}
	async LoadFiles() {
		this.ShowLoader();
		try {
			const hosts   = await this.GetFileContent( "hosts" );	
			const exclude = await this.GetFileContent( "exclude" );	
			this.originalContent.file1 = hosts;
			this.originalContent.file2 = exclude;
			this.currentContent.file1  = hosts;
			this.currentContent.file2  = exclude;
			document.getElementById('file1').value = hosts;
			document.getElementById('file2').value = exclude;	
			this.HideLoader();
			this.ShowNotification('Файлы загружены', 'success');

		} catch (error) {
			console.error('Ошибка загрузки файлов:', error);
			this.ShowNotification('Ошибка загрузки файлов', 'error');
			this.HideLoader();
		}
	}
	async ControlApp( action ) {
		this.ShowLoader();
		this.LockButtons();
		try {
			const result = await this.SendRequest( action );
			this.UpdateStatus( parseInt( result.isRunning ) > 0 ? 1 : 0 );
			this.ShowNotification( `Приложение ${this.GetActionText(action)}` , result.code == 0 ? 'success' : 'error' );
		} catch ( error ) {
			this.ShowNotification( `Ошибка при ${this.GetActionText(action)}` , 'error' );
		} finally {
			this.HideLoader();
		}
	}
	LockButtons() {
		const buttons = document.querySelectorAll( '.btn' );
			  buttons.forEach( btn => btn.disabled = true );
	}
	GetActionText( action ) {
		const actions = {
			'start': 'запущено',
			'stop': 'остановлено',
			'restart': 'перезапущено'
		};
		return actions[ action ] || action;
	}
	async SaveAllFiles() {
		this.ShowLoader();
		try {
			// Проверяем изменения
			let changes = 0;
			if ( this.currentContent.file1 !== this.originalContent.file1 ) {
				await this.WriteFileContent( "hosts" , this.currentContent.file1 );
				this.originalContent.file1 = this.currentContent.file1;
				changes++;
			}
			if ( this.currentContent.file2 !== this.originalContent.file2 ) {
				await this.WriteFileContent( "exclude" , this.currentContent.file2 );
				this.originalContent.file2 = this.currentContent.file2;
				changes++;
			}
			if ( changes === 0 ) {
				this.ShowNotification( 'Нет изменений для сохранения' , 'warning' );
				this.HideLoader();
				return;
			}
			this.ShowNotification( `Сохранено файлов: ${changes}` , 'success' );
		} catch ( error ) {
			console.error( 'Ошибка сохранения:' , error );
			this.ShowNotification( 'Ошибка сохранения файлов' , 'error' );
		} finally {
			this.HideLoader();
		}
	}
	UpdateStatus( running ) {
		this.isRunning   = running;
		const statusDot  = document.getElementById('statusDot');
		const statusText = document.getElementById('statusText');
		console.log( running , "set" );
		if ( this.isRunning ) {
			statusDot.className    = 'status-dot running';
			statusText.textContent = 'Запущено';
			document.getElementById( 'btnStart' ).disabled   = true;
			document.getElementById( 'btnStop' ).disabled    = false;
			document.getElementById( 'btnRestart' ).disabled = false;
		} else {
			statusDot.className    = 'status-dot';
			statusText.textContent = 'Не запущено';
			document.getElementById( 'btnStart' ).disabled   = false;
			document.getElementById( 'btnStop' ).disabled    = true;
			document.getElementById( 'btnRestart' ).disabled = true;
		}
	}
	ShowNotification( message , type = 'success' ) {
		const notification = document.getElementById('notification');
		notification.textContent = message;
		notification.className = 'notification';
		notification.classList.add('show', type);
		
		setTimeout(() => {
			notification.classList.remove('show');
		}, 3000);
	}
	ShowLoader() {
		document.getElementById('loader').classList.add('active');
	}
	HideLoader() {
		document.getElementById('loader').classList.remove('active');
	}
}
// Инициализация при загрузке страницы
document.addEventListener('DOMContentLoaded', async () => {
	const adminPanel = new AdminPanel();
	const result     = await adminPanel.SendRequest( "status" );
	adminPanel.UpdateStatus( parseInt( result.isRunning ) > 0 ? 1 : 0 );
});