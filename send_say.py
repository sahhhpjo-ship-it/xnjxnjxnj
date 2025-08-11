import asyncio
import os
from pyrogram import Client, filters
from pyrogram.handlers import MessageHandler
from command import fox_command  # Импортируем fox_command из command.py

fox_sudo = None  # Определение fox_sudo для предотвращения ошибки

# Получаем имя файла для использования в fox_command
file = __file__  # Используем __file__ для получения имени текущего файла
basename = os.path.basename(file)

# Определение команды say
@Client.on_message(filters.me & fox_command("say", "Отправляет текст, указанный пользователем", basename))
async def say_command(client, message):
    """Отправляет текст, указанный пользователем."""
    try:
        # Получаем текст сообщения
        text = message.text.split(maxsplit=1)[1] if len(message.text.split()) > 1 else None

        # Проверяем, что текст указан
        if not text:
            await message.edit("Ошибка: Текст сообщения не указан. Используйте: say [текст]")
            return

        # Удаляем сообщение команды
        await message.delete()

        # Отправляем текст
        await client.send_message(message.chat.id, text)

    except Exception as e:
        print(f"Произошла ошибка: {e}")


print("Модуль say.py загружен")

