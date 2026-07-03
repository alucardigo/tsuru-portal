**Assunto: Tsuru — Portal de Gestão de PD&I e Lei do Bem — Reporte de desenvolvimento e apresentação à Diretoria**

Prezados membros da Diretoria,

Escrevo para apresentar o **Tsuru**, o portal interno que estamos construindo para gerir todo o ciclo de Pesquisa, Desenvolvimento e Inovação (PD&I) da Bellube, incluindo o processo de elegibilidade e defesa da Lei do Bem — e para reportar o estágio atual do desenvolvimento.

**O problema que estávamos resolvendo**

Até então, o controle de projetos de inovação da empresa era feito em planilhas soltas, e-mail e memória institucional. Isso trazia dois riscos concretos:

- **Risco fiscal**: o dossiê de defesa da Lei do Bem era remontado do zero a cada ano-base, sem rastreabilidade formal de decisões — um dos critérios mais comuns de recusa do benefício pelo Comitê de Apoio Técnico (CAT) do MCTI é justamente a "cópia de relato entre anos sem evidência de progresso técnico distinto".
- **Risco de gestão**: não havia como saber, num relance, quantos projetos de inovação estavam de fato avançando e quantos estavam simplesmente parados esperando alguém responder.

**O que construímos**

O Tsuru modela o funil completo de inovação da empresa — da sugestão de um colaborador até a defesa final perante o MCTI — como um processo auditável, com histórico de decisões que não pode ser apagado ou reescrito, nem por um erro de sistema. Ele já está em produção, com:

- **119 usuários reais** cadastrados, reconciliados entre o Sankhya e o Microsoft 365.
- **Mais de 30 projetos e sugestões** de inovação cadastrados e em acompanhamento.
- Um **painel executivo** que separa, de forma objetiva, o que está de fato em andamento do que está parado esperando uma decisão — de qualquer pessoa, inclusive da própria Diretoria.
- Integração com o Sankhya e compatibilidade com o Microsoft Power Automate.
- Uma API e um conector de inteligência artificial que já permitem que o próprio time de T&I administre e evolua o sistema com apoio de ferramentas de IA.

**Um ponto de transparência que vale reportar diretamente**

Durante o desenvolvimento, identificamos e corrigimos um problema real: a primeira versão da rotina que marcava usuários como desligados usava apenas a ausência de login no Sankhya como sinal — e essa heurística errou em 16 de 22 casos, sinalizando colaboradores que continuam empregados normalmente. Cruzamos a informação diretamente com a base de RH do próprio Sankhya (data de demissão real) e corrigimos as 16 contas incorretamente marcadas antes que isso gerasse qualquer impacto prático. Trago esse ponto porque ele também é, tecnicamente, uma evidência forte do tipo de incerteza real que sustenta o enquadramento do projeto na Lei do Bem — não estamos implantando um sistema de prateleira, estamos resolvendo problemas de engenharia que não tinham resposta óbvia de antemão.

**Anexos deste e-mail**

1. **Tsuru_Documentacao_Tecnica.pdf** — documentação técnica completa da ferramenta (arquitetura, funcionalidades, stack, estado atual e débitos conhecidos).
2. **Tsuru_Lei_do_Bem_Dossie_N3.pdf** — dossiê de defesa técnica (N3) do próprio projeto Tsuru para fins de Lei do Bem, com os pontos que ainda precisam de anexo de evidência (financeiro e capturas de tela) sinalizados no documento.

**Próximos passos sugeridos**

- Agendar uma apresentação rápida (15–20 min) do painel para a Diretoria, mostrando o funil em produção com dados reais.
- Validar com a área financeira os dispêndios do Bloco 5 do dossiê Lei do Bem, para que a submissão ao FORMP&D possa ser preparada com o benefício fiscal calculado.
- Definir se o Tsuru passa a ser a fonte oficial de acompanhamento de projetos de inovação da empresa, substituindo o controle paralelo em planilhas.

Fico à disposição para qualquer esclarecimento ou para agendar a apresentação.

Atenciosamente,
[Nome]
[Cargo] · Bellube
