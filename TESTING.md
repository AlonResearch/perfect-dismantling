# Como testar o Perfect Dismantling in-game

Este guia testa se o mod esta carregando e se o desmonte devolve os ingredientes corretos no The Witcher 3 Next-Gen 4.04.

## 1. Antes de abrir o jogo

1. Confirme que o mod instalado existe em:

```text
C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3\Mods\modPerfectDismantling
```

2. Confirme que dentro dele existem:

```text
content\blob0.bundle
content\metadata.store
```

3. Abra o Witcher Script Merger.

4. Rode o scan de conflitos.

5. Se aparecer conflito de scripts, ele provavelmente vem de outro mod, porque Perfect Dismantling 0.1 Alpha nao inclui scripts.

6. Se aparecer conflito de bundles/XML/item definitions, anote quais arquivos conflitaram. O mod pode conflitar com outros mods que alteram os mesmos `def_item_*.xml`.

## 2. Primeiro teste: item craftado simples

Objetivo: confirmar que o mod esta carregando.

1. Entre no jogo.

2. Va ate um ferreiro ou armeiro.

3. Escolha um item craftado simples, de preferencia uma espada ou armadura que voce consiga fabricar e desmontar facilmente.

4. Antes de craftar, anote os ingredientes exibidos na tela de criacao.

Exemplo:

```text
Item craftado: Short sword 1_crafted
Ingredientes na tela de craft:
- 1 Leather squares
- 2 Iron ingot
```

5. Fabrique o item.

6. Va para a aba de desmonte.

7. Selecione o item fabricado.

8. Compare os itens que o desmonte vai devolver com os ingredientes anotados.

Resultado esperado: o desmonte deve devolver exatamente os ingredientes diretos da receita.

## 3. Teste de Witcher gear com upgrade

Objetivo: confirmar a regra de "um passo para tras".

1. Escolha uma peca de equipamento Witcher que usa uma versao anterior como ingrediente.

Exemplo:

```text
Grandmaster Boots
```

2. Na tela de craft, anote a versao base exigida e os materiais adicionais.

Exemplo esperado de log:

```text
Item craftado: Bear Boots 5
Receita exige:
- 1 Bear Boots 4
- materiais adicionais da receita
```

3. Fabrique ou use uma peca existente desse tier.

4. Va para a aba de desmonte.

5. Selecione a peca upgraded.

Resultado esperado: o desmonte deve devolver a peca anterior, por exemplo `Bear Boots 4`, mais os materiais usados naquele upgrade. Ele nao deve quebrar recursivamente `Bear Boots 4` em todos os tiers anteriores.

## 4. Teste com runas, glifos e upgrades encaixados

Objetivo: confirmar que o comportamento nativo do jogo continua funcionando.

1. Pegue uma arma ou armadura com slots.

2. Coloque uma runa, glifo ou upgrade no item.

3. Anote exatamente o que foi colocado.

Exemplo:

```text
Item: espada craftada
Upgrade encaixado:
- Rune stribog
```

4. Va para o desmonte.

5. Selecione esse item.

Resultado esperado: o jogo deve devolver os ingredientes da receita gerada pelo Perfect Dismantling e tambem devolver a runa/glifo/upgrade se o comportamento vanilla ja expuser isso para aquele item.

Observacao: a versao 0.1 Alpha nao adiciona script proprio para recuperar upgrades. Ela preserva o fluxo vanilla de `GetItemRecyclingParts`.

## 5. Teste New Game+

Objetivo: confirmar que os arquivos `items_plus` foram carregados.

1. Abra um save New Game+.

2. Repita o teste de item craftado simples.

3. Repita o teste de Witcher gear upgraded.

Resultado esperado: os itens NG+ devem seguir a mesma regra de devolver os ingredientes diretos da receita NG+.

## 6. Teste DLC

Objetivo: confirmar que HoS e Blood and Wine entram no pacote.

1. Teste pelo menos um item de Hearts of Stone.

2. Teste pelo menos um item de Blood and Wine.

3. Para Blood and Wine, priorize um item Grandmaster, porque ele e o caso mais importante para a regra de downgrade.

Resultado esperado: itens DLC devem desmontar em seus ingredientes diretos de receita.

## 7. Casos conhecidos que podem nao bater

Estes casos foram pulados de proposito pelo gerador 0.1 Alpha:

- Receitas ambiguas, onde o mesmo item tem mais de uma receita.
- Receitas que produzem stacks, como bolts/dardos que produzem 20 unidades.
- Itens novos adicionados por outros mods, a menos que o XML desse mod seja incluido em um fluxo de geracao customizado.
- Itens vanilla alterados por outro mod podem conflitar se o outro mod sobrescrever o mesmo arquivo XML.

## 8. Como reportar um problema

Ao encontrar um item com desmonte errado, anote:

```text
Versao do jogo:
Lista de mods ativos:
Item testado:
Item era vanilla, DLC ou de outro mod?
Receita exibida na tela de craft:
Resultado exibido na tela de desmonte:
O item tinha runa/glifo/upgrade encaixado?
Save era NG ou NG+?
Arquivo de conflito apontado pelo Script Merger, se houver:
```

Se possivel, inclua screenshot da tela de craft e da tela de desmonte.
