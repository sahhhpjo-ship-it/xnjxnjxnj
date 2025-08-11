import asyncio
import os
from pyrogram import Client, filters
from pyrogram.handlers import MessageHandler

# Попытка импортировать PREFIX из prefix.py, если не получается, используем префикс по умолчанию
try:
    from prefix import PREFIX
except ImportError:
    PREFIX = "."
    print("Ошибка: Не удалось импортировать PREFIX из prefix.py. Используется префикс по умолчанию ('.')")

# Получаем имя файла для использования в fox_command
file = __file__  # Используем __file__ для получения имени текущего файла
basename = os.path.basename(file)


def fox_command(command, description, file_basename, usage=""):
    """Декоратор для регистрации команд в FoxUserbot."""
    def decorator(func):
        @Client.on_message(filters.command(command, prefixes=PREFIX) & filters.me)
        async def wrapper(client, message):
            await func(client, message)  # Вызываем функцию обработчика
        wrapper.__doc__ = f"{description}\nИспользование: `{PREFIX}{command} {usage}`"  # Добавляем документацию
        return wrapper  # Возвращаем функцию

    return decorator


@fox_command(command="fmsg", description="Отправляет текст в избранное", file_basename=basename, usage="[текст]")
async def send_to_favorites(client, message):
    """Отправляет указанный текст в Избранное."""
    try:
        if len(message.command) < 2:
            await message.edit("<i>Ошибка: Текст сообщения не указан. Используйте: `[префикс]fmsg [текст]`</i>")
            return

        text = " ".join(message.command[1:])
        await message.delete()  # Удаляем сообщение команды

        await client.send_message("me", text)

    except Exception as e:
        try:
            await client.send_message(message.chat.id, f"<i>Ошибка при отправке в избранное:</i> {e}")
        except:
            print(f"Произошла ошибка {e}") # Если send_message не сработает, то выводим в консоль


@fox_command(command="help_fmsg", description="Помощь по команде fmsg", file_basename=basename)
async def help_fmsg(client, message):
    """Выводит справку по команде fmsg."""
    await message.edit(
        f"""<b>fmsg</b> - Отправляет текст в избранное.\nИспользование: `{PREFIX}fmsg [текст]`"""
    )


