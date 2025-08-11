import asyncio
import os
from pyrogram import Client, filters
from pyrogram.handlers import MessageHandler
from command import fox_command  # Импортируем fox_command из command.py

# Получаем имя файла для использования в fox_command
file = __file__  # Используем __file__ для получения имени текущего файла
basename = os.path.basename(file)


@Client.on_message(fox_command("fmsg", "Отправляет текст в избранное", basename, "[текст]") & filters.me)
async def send_to_favorites(client, message):
    """Отправляет указанный текст в Избранное."""
    try:
        if len(message.command) < 2:
            await message.edit("<i>Ошибка: Текст сообщения не указан. Используйте: fmsg [текст]</i>")
            return

        text = " ".join(message.command[1:])
        await message.delete()  # Удаляем сообщение команды

        await client.send_message("me", text)

    except Exception as e:
        try:
            await client.send_message(message.chat.id, f"<i>Ошибка при отправке в избранное:</i> {e}")
        except:
            print(f"Произошла ошибка {e}") # Если send_message не сработает, то выводим в консоль


@Client.on_message(fox_command("help_fmsg", "Помощь по команде fmsg", basename) & filters.me)
async def help_fmsg(client, message):
    """Выводит справку по команде fmsg."""
    await message.edit(
        f"""<b>fmsg</b> - Отправляет текст в избранное.\nИспользование: fmsg [текст]"""
    )


