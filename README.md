Это PPL-KILLER драйвер написанный на ассемблере FASM x64.
1. Он получает информацию о всех запущенных процессах через - ZwQuerySystemInformation
2. Выделяется динамическая память с целью сохранения буфера всех процессов с тэгом "PPLL" - ExAllocatePoolZero
3. Второй вызов ZwQuerySystemInformation с уже выделенным буфером, теперь функция заполняет его реальными данными, сязным списком структур SYSTEM_PROCESS_INFORMATION, по одной на каждый процесс
4. Оюход списка в цикле, чтение UniqueProcessId(смещение разное относительно версии ОС), сохраняется PID первого же PPL процесса и он убивается через ZwTerminateProcess.
5. <img width="1125" height="157" alt="изображение" src="https://github.com/user-attachments/assets/ae056f4d-fb2c-4339-92a3-c05e81b855b1" />

