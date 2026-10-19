# Terminal

```bash
bash setup.sh install terminal
```

Instala Zsh, Oh My Zsh, Spaceship e Zinit com completions, sugestões e destaque
de sintaxe. A seção antiga `vi_mode` não é usada.

A configuração fica em `~/.config/script-up-server/terminal.zsh`. O `.zshrc` é
preservado e recebe uma linha para carregá-la. Se houver configuração manual
de Oh My Zsh, revise o arquivo para não carregá-lo duas vezes. A linha gerada
pelo instalador Rocketseat anterior é substituída automaticamente, com backup.

Backups: `~/.local/state/script-up-server/`. `chsh` pode pedir senha. Entre
novamente na sessão ou execute `exec zsh` para usar o shell.

## Dracula e Fira Code

GNOME Terminal recebe Dracula e Fira Code se a sessão gráfica estiver disponível.
O perfil anterior é exportado para o backup.

Windows Terminal é um aplicativo Windows. Instalar Fira Code no Ubuntu não a
instala no Windows: instale-a também pelas configurações de fontes do Windows.
No JSON do Windows Terminal, adicione o objeto de
`config/windows-terminal-dracula.json` à lista `schemes`. Mescle no perfil Ubuntu:

```json
{
  "colorScheme": "Dracula",
  "font": { "face": "Fira Code" }
}
```

Não substitua o arquivo inteiro por esse fragmento. Cores e fontes são opções
do terminal; Spaceship configura o conteúdo do prompt.
