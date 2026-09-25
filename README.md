# Backend - API REST (Node.js + Express)

projeto de infraestrutura para sistemas distribuidos com exemplo simples e prático de uma api rest com nodejs e express, com um crud simples de usuarios, enpoint de upload de arquivo para bucket S3 na AWS, pipeline no github actions, build com imagem docker, armazenamento em AWS ECR, deploy em multiplas instancias EC2 na AWS, com multi AZ, ALB

Vídeo explicativo sobre o projeto: https://youtu.be/wv6KditGAAI

Abri na comunidade do Discord um grupo para discutirmos sobre ensino de tecnologia no Brasil em diversos níveis de cursos: https://www.rafaellevi.com.br/comunidade-discord.html

CRUD simples de `usuarios` + upload de imagens para o S3, conectado a um MySQL no RDS.


## Rodando localmente

```bash
npm install
cp .env.example .env   # preencha com seus dados de RDS/S3
npm run dev
```

A API sobe em `http://localhost:3000`.

## Rotas

| Método | Rota          | Descrição                          |
|--------|---------------|--------------------------------------|
| GET    | `/`           | Health check                         |
| GET    | `/usuarios`   | Lista todos os usuários              |
| GET    | `/usuarios/:id` | Busca um usuário pelo id           |
| POST   | `/usuarios`   | Cria um usuário (`nome`, `email`, `foto_url`) |
| PUT    | `/usuarios/:id` | Atualiza um usuário                |
| DELETE | `/usuarios/:id` | Remove um usuário                  |
| POST   | `/upload`     | Upload de imagem (form-data, campo `imagem`) → retorna a URL pública no S3 |

## Banco de dados

Execute `src/db/schema.sql` no seu MySQL (RDS) antes de usar a API.

## Docker

```bash
docker build -t api-backend .
docker run -p 3000:3000 --env-file .env api-backend
```

## Deploy

O pipeline em `.github/workflows/deploy-backend.yml` builda a imagem, publica no ECR
com tag semântica e faz o deploy via SSH em uma instância EC2. Veja o `README.md`
na raiz do projeto para o passo a passo completo.


## Explicação em vídeo

https://youtu.be/wv6KditGAAI

## Diagrama

[![](https://mermaid.ink/img/pako:eNq9V9tu2zYYfhVCRRcHs-xIdhxHawL42AZIUs9yW6DzUNASbRORRY-kEqcHYLtfsa3YxbabottFhwG9HzBgN36TvsD6CPspynKcxGmNFFVyIYo__8PH7z_4ieExnxiO0Q_YiTfEXKJOvRsieG7eRA0haUAf4-nr6R8M9bAgaIw5RiIaMy4xR0yg6RuPhUQg9_5tlGlGoQ-CHIce06KwKTkWkqxrrV6AhaiTPgqJPGH8CPVpEDg3mvGTFZKzI-LcKNeK86V5Qn05dOzxJOuxgHHnhl2wm4VGtg-6zRNCB0Pp9Fjgf3HOhCBexKk8vdxGY8va3Kpe14bHRuNIkstN1K2CbdnXNeH3LtdeqBbLtdq1QZKM48GSAArNcskuXtdEJAif6d9Wf6n-RMHq-lOKVsB9YB9BLRACOvoENRTjfKxF7oHtTObdy5_-fPvt83cvX_xzq8d374lo-opTEL9PuYwwFeprhwBNlYIa5gO8vu44jvJc60kNVhn3MWpMJOEhRiaqH7pg3SWDCFg_fZ2YFVFvwPF4iBo-YPtV13j38vvnevEZarNI0nCAMh04IiBNpn-FHsXK9D7zcJpx613ja61OPe3NAui5RUcDJLi3szaUciycfJ5CiuWoR8Y4JEGOsnzlgZsXx4P8oc4wsGTWABwCINZJQI8JP80rF4i5WciB4BqKgd9ZK26sofyuggJUxF4StFlQ6zaTBI9AA1PxgluATZLAcwcfVJqrOegm-Wnu-aBavdQgmwIK1YPkQdsVzsGuem1STk5wECjoKnDS08BpB2fprz0koX-GNvoW4f8wOiYjuMY2ARWaDQFqcXqcMii9yvutmrrJt79899_fPyzKAlC1gEU-yoDQOqiLhEmg6pnWwhXO3yr71Y93mQ1INEk9c59h36ziAPADuWXojWOcJGUhUgeQPkC42vwcdYD7RKLbnEVjce6i5-6nmFTc2zEmv_2qMKlEQBBXMRjYHatAmYaANe5BH_ExQHyHcfoYAsDBIrsX4Vm08fBRRRl5ePewgiook2KLL6pQT6NmP6qshm5NV_E8HF0C214o5PT3OE1BKAaytYfUVWAaQnmzNFZJO1h0KqbehwVaTQOtngm0tzzQ6qcO1H5foPNP55ZpnHUscYeCrrguvvg3_gB10U1aUbyXaREuKPgS18aLALTr7mqhKyNqhMnDyWW5McLATaVarQ5O3S_3dbR-b9G4u2IpTiLLuxTqGzGTpekSfgziV3vjxhX43jiAZBX5ihBEJomZtO5zgF8kWQr8XtjnODEqNPo__wgFQKiupJJ3lNbPc_EefMTKDpscYjAPcAje8yuqfCKJEkn1ucahUCtGUIHq1csK_Tw72qvmRsJxkVbU9JPZJgMgIz-9-q7AplrVmXcEFJ6dWZIx6W0ttqZmEE1YPIbAXD1Rg7cJE8mIhkOGanz6Bvxi89kG7eygrtEm30RUUD2n3-l0WtCjYWdXDQ1aFl6QmYtFBQuOCeznzF3VR_U-vCDThP0mDWB8QpJPX_XJAKgAn3dVvzo_B-m2kUwFs6npspmmiYMhTsZ_0KP8egrDRejDiNGjIcqjOwQHcojuHj3VxXsF2eoZ5IBjUTibAaC5CzQvZkJN6ijm_vQ1DH6VaAItCcPsqI_HdjVCVg5VI-ha6AzXErjcgwvSdg61IphA9kZA0RHSV5-IAx3m8tWVtFc_UPuy4AkUVZ8tBHcroYoqIw8gX4iYkaTunjX8frkFEBRpdHXSXoYi4YxbWAjnSrluaGSNAae-4UgekawxInyE1dJ4orR0DTkkI2CtA68AXDQxfcyPzPiHQtfohs_gPGT0Q8ZGMxUwfwyGhtPHgYBVNPZhTKtTDKVwLgKpR3gNCCYNp1y2Yh2G88SYGI5VsnIbdqFobxWtjeL2VsnOGqeGY1r2xnaubG2XSoWNUtkuFcvPssbj2K6dK9jlUqlsWVubdsHaLhSzBvEplOkD_Ss7_rH97H_9ZPdW?type=png)](https://mermaid.live/edit#pako:eNq9V91u2zYUfhVCRRcHs-xYdhxHawL4tw2QpJ7ltEDnoaAl2iYiiR5JJU7bANv9im3FLrbdFN0uOgzo_YABu_Gb9AXWR9ihqMhxEqc1UlTJhSgenp-P3_nxU8NlHjFsY-CzY3eEuUTdRi9E8Ny-jZpCUp8-wdPX0z8Y6mNB0BhzjEQ0ZlxijphA0zcuC4lAzoO7KNOKQg8EOQ5dpkVhU3IsJFnVWl0fC9EgAxQSecz4IRpQ37dvteInKyRnh8S-VamXZkvzmHpyZFvjSdZlPuP2LatotYrN7AB0m8eEDkfS7jPf--KCCUHciFN5crWN5kZhfaN2UxsuC8aRJFebaBSKVsG6qQmvf7X2Yq1UqddvDJJkHA8XBFBsVcpW6aYmIkH4mf5N9ZfqTxQsrz-laBXcB_YR1AYhoKNHUFMxzsNa5ABsZzLvXv7059tvn797-eKfO32-fSCi6StOQfwB5TLCVKivXQI0VQrqmA_x6qpt28pzrSc1WGPcw6g5kYSHGJmose-AdYcMI2D99HViVkT9IcfjEWp6gO1XPePdy--f68VnqMMiScMhynThiIA0mf4VuhQr07vMxWnGrfaMr7U69XTWi6DnDg2GSHB3a2Uk5VjY-TyFFMtRl4xxSPwcZfnqQycvjob5fZ1hYMmsAzgEQGwQnx4RfpJXLhBzvZgDwRUUA7-1UlpbQfltBQWoiL0kaL2o1h0mCQ5AA1PxgluATZLAMwcfVlvLOegk-WnueKBavdQhm3wK1YPkQds1zsGuem1RTo6x7yvoqnDS1cBpB8_SX3tIQu8cbfQtwv9-dEQCuMYOARWaDT5qc3qUMii9ygfturrJt79899_fP8zLAlB1n0UeyoDQKqiLhEmg6pmFuSucvVV3ax_vMpuQaJK65i7DnlnDPuAHcovQG8c4ScpCpA4gfYBwtfk56gL3iUR3OYvG4sJFz9xPMak6d2NMfvtVYVKNgCCOYjCwO1aBMk0Ba9yHPuJhgPge4_QJBID9eXbPwzNv49HjqjLy6P5-FVVRJsUWX1ahnmbdelxdDt26ruJ5OLoAtp1QyOnvcZqCUAxkewepq8A0hPJW0Fgl7WDeqZh6HxZoLQ20di7Q_uJAa586UOt9gc4-XVimcTawxF0KuuK6-OLf-APURSdpRfFepk24oOBLXBsvA9BpOMuFroyoESYPJxflRoCBm0q1Wu2dOF_u6mi9_rxxZ8lSnESWdyjUN2ImS9Mh_AjEr_fGiSvwwdiHZBX5qhBEJomZtO4LgF8mWQr8TjjgODEqNPo__wgFQKiupJI3SOvnhXj3PmJlh00OMZh7OATv-TVVPpFEiaT6XOdQqBUjqECN2lWFfpYdnWVzI-G4SCtq-snskCGQkZ9cf1dgU60azD0ECp-dWZAx6W3Nt6aWH01YPIbAXD1Rg7cJE0lAwxFDdT59A36x2WyDtrZQz-iQbyIqqJ7T73W7bejRsLOthgYtCy_IzMWigvlHBPZz5rbqo3ofXpBpwn6L-jA-IcmnrwZkCFSAz9uqX12cg3TbSKaCs6npqpmmhf0RTsZ_0KP8egbDRejBiNGnIcqjewT7coTuHz7TxXsJ2do55IBjUXg2A0BzF2hWzISa1FHM_elrGPyq0QRaEobZUR-P7WqECjlUi6BroXNcS-By9i5JWznUjmAC2QmAogHSV5-IAx1m8rWltNc-UPui4AkUVY_NBXcnoYoqIw8hX4g4I0nDOW_4_XJzICjS6OqkvQxFwhmnOBfOtXK90MgaQ049w5Y8IlkjIDzAamk8VVp6hhyRAFhrwysAF01MD_NDM_6h0DN64Smch4x-xFhg2APsC9ABA8hwlK6isQdzWoNiqIXnZCD5CK8DxaRhVzbKsRbDfmpMDLtQLuTWrGLJ2igV1kqbG2Ura5wYtlmw1jZzlcJmuVxcK1escqlymjWexJatXNGqlMuVwka5UKlUiptZg3gU6vSe_pkd_9o-_R__w_fP)
