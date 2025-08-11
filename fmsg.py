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

# Добавляем handler в список
send_to_favorites_handler = send_to_favorites


@Client.on_message(fox_command("help_fmsg", "Help for fmsg", os.path.basename(file)) & filters.me)
async def help_fmsg(client, message):
    await message.edit(
        f""".fmsg [текст] - Отправляет указанный текст в избранное. Префикс: {PREFIX}""" # показываем префикс в справке
    )

help_fmsg_handler = help_fmsg
