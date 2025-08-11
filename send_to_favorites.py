import asyncio
import os
from pyrogram import Client, filters
from pyrogram.handlers import MessageHandler
from command import fox_command  # Импортируем fox_command из command.py

# Получаем имя файла для использования в fox_command
file = __file__  # Используем __file__ для получения имени текущего файла
basename = os.path.basename(file)

# Определение команды fmsg
@Client.on_message(filters.me & fox_command("fmsg", "Отправляет текст в избранное", basename))
async def send_to_favorites(client, message):
    """Отправляет указанный текст в Избранное."""
    try:
        # Получаем текст сообщения
        text = message.text.split(maxsplit=1)[1] if len(message.text.split()) > 1 else None

        # Проверяем, что текст указан
        if not text:
            await message.edit("Ошибка: Текст сообщения не указан. Используйте: fmsg [текст]")
            return

        # Удаляем сообщение команды
        await message.delete()

        # Отправляем текст в Избранное
        await client.send_message("me", text)

    except Exception as e:
        try:
            await client.send_message(message.chat.id, f"Ошибка при отправке в избранное: {e}")
        except:
            print(f"Произошла ошибка {e}")  # Если send_message не сработает, то выводим в консоль


# Определение команды help_fmsg
@Client.on_message(filters.me & fox_command("help_fmsg", "Помощь по команде fmsg", basename))
async def help_fmsg(client, message):
    """Выводит справку по команде fmsg."""
    await message.edit(
        f"""fmsg - Отправляет текст в избранное.\nИспользование: fmsg [текст]"""
    )


print("Модуль send_to_favorites.py загружен")

