import asyncio
from pyrogram import Client, filters  # Добавлена строка импорта Client
import os

# Попытка импортировать PREFIX из prefix.py
try:
    from prefix import PREFIX
except ImportError:
    PREFIX = "."  # Значение по умолчанию, если prefix.py отсутствует или PREFIX не определен
    print("Ошибка: Не удалось импортировать PREFIX из prefix.py. Используется префикс по умолчанию ('.').")

def fox_command(*args, **kwargs):
    """Декоратор для команд, использующий префикс из prefix.py."""
    command = args[0]
    def decorator(func):
        @filters.command(command, prefixes=PREFIX) & filters.me  # Используем PREFIX здесь
        async def wrapper(client, message):
            return func(client, message)
        return wrapper
    return decorator


@Client.on_message(fox_command("fmsg", "Send message to favorites", os.path.basename(file), "[text]") & filters.me)
async def send_to_favorites(client, message):
    """
    Отправляет текстовое сообщение в избранное.
    Использование: [prefix]fmsg [текст]
    """
    try:
        text = " ".join(message.command[1:])  # Получаем текст сообщения из команды
        if not text:
            await message.edit("Ошибка: Текст сообщения не указан. Используйте [prefix]fmsg [текст]")
            return
    except IndexError:
        await message.edit("Ошибка: Текст сообщения не указан. Используйте [prefix]fmsg [текст]")
        return

    await message.delete()  # Удаляем сообщение с командой

    try:
        await client.send_message("me", text)  # "me" - это alias для избранного
    except Exception as e:
        await client.send_message(message.chat.id, f"Ошибка при отправке сообщения в избранное: {e}")


@Client.on_message(fox_command("help_fmsg", "Help for fmsg", os.path.basename(file)) & filters.me)
async def help_fmsg(client, message):
    await message.edit(
        f""".fmsg [текст] - Отправляет указанный текст в избранное. Префикс: {PREFIX}""" # показываем префикс в справке
    )


@Client.on_message(fox_command("help_fmsg", "Help for fmsg", os.path.basename(file)) & filters.me)
async def help_fmsg(client, message):
    await message.edit(
        f""".fmsg [текст] - Отправляет указанный текст в избранное. Префикс: {PREFIX}""" # показываем префикс в справке
    )

help_fmsg_handler = help_fmsg
