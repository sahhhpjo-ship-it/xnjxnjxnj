import asyncio
import os
from pyrogram import Client, filters
from pyrogram.handlers import MessageHandler
from command import fox_command  # Импортируем fox_command из command.py

# Получаем имя файла для использования в fox_command
file = __file__  # Используем __file__ для получения имени текущего файла
basename = os.path.basename(file)

# Получаем результат fox_command
command_filter = fox_command("say", "Отправляет текст, указанный пользователем", basename)

# Проверяем, что fox_command вернул что-то, кроме None
if command_filter is not None:
    # Определение команды say
    @Client.on_message(filters.me & command_filter)
    async def say_command(client, message):
        """Отправляет текст, указанный пользователем."""
        try:
            # Получаем текст из сообщения, используя более надежный способ
            args = message.text.split()
            if len(args) > 1:
                text = " ".join(args[1:])  # Соединяем все аргументы после команды
            else:
                text = None

            # Проверяем, что текст указан
            if not text:
                await message.edit("Ошибка: Текст сообщения не указан. Используйте: say [текст]")
                return

            # Удаляем сообщение команды
            await message.delete()

            # Отправляем текст
            try:
                await client.send_message(message.chat.id, text)
            except Exception as send_error:
                print(f"DEBUG: Ошибка при отправке сообщения: {send_error}")
                await message.reply_text(f"Ошибка при отправке сообщения: {send_error}")


        except Exception as e:
            print(f"DEBUG: Общая ошибка: {e}")
            await message.reply_text(f"Произошла ошибка: {e}")

    print("Модуль say.py загружен")
else:
    print("Ошибка: fox_command вернул None. Модуль say.py не загружен.")


