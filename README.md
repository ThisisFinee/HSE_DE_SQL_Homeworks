# Домашняя работа

## Навигация
- [Построение и запуск](#построение-и-запуск)
- [Домашние работы](#домашние-работы)
  - [Homework-2](#homework-2)
  - [Homework-3](#homework-3)
  - [Homework-4](#homework-4)
  - [Homework-5](#homework-5)
  - [Homework-6](#homework-6)
  - [Homework-7](#homework-7)
  - [Homework-8](#homework-8)
  - [Homework-9](#homework-9)
  - [Homework-Final](#homework-final)

## Построение и запуск

1) Построение образа и запуск контейнера для домашних работ.

Для обычных домашних работ:

```bash
chmod +x scripts/bootstrap_demo_small.sh
./scripts/bootstrap_demo_small.sh
```

Для финальной работы:

```bash
chmod +x scripts/bootstrap_ad_platform.sh
./scripts/bootstrap_ad_platform.sh
```

После запуска ожидаем, пока выполнятся все пункты bootstrap-скрипта (придётся немного подождать).

2) Заходим в контейнер:

```bash
docker compose exec -it postgres bash
```

3) Заходим в БД.

Для обычных домашних работ:

```bash
psql -U postgres -d demo
```

Для финальной работы:

```bash
psql -U postgres -d ad_platform
```

4) Далее можно либо выполнять задания вручную (они описаны в `README.md` каждой домашней работы), либо выполнить решения из `.sql` файлов напрямую внутри `psql`.

Пример запуска для Homework-2:

```sql
\i /work/Homework-2/solutions.sql
```

---

## Домашние работы


### Homework-2
- Директория: [`Homework-2/`](Homework-2/)
- Полное решение: [`Homework-2/solutions.sql`](Homework-2/solutions.sql)
- Полное описание: [`Homework-2/README.md`](Homework-2/README.md)

Запуск внутри `psql`:

```sql
\i /work/Homework-2/solutions.sql
```

### Homework-3
- Директория: [`Homework-3/`](Homework-3/)
- Полное решение: [`Homework-3/solutions.sql`](Homework-3/solutions.sql)
- Полное описание: [`Homework-3/README.md`](Homework-3/README.md)

Запуск внутри `psql`:

```sql
\i /work/Homework-3/solutions.sql
```

### Homework-4
- Директория: [`Homework-4/`](Homework-4/)
- Полное решение: [`Homework-4/solutions.sql`](Homework-4/solutions.sql)
- Полное описание: [`Homework-4/README.md`](Homework-4/README.md)

Запуск внутри `psql`:

```sql
\i /work/Homework-4/solutions.sql
```

### Homework-5
- Директория: [`Homework-5/`](Homework-5/)
- Полное решение: [`Homework-5/solutions.sql`](Homework-5/solutions.sql)
- Полное описание: [`Homework-5/README.md`](Homework-5/README.md)

Запуск внутри `psql`:

```sql
\i /work/Homework-5/solutions.sql
```

### Homework-6
- Директория: [`Homework-6/`](Homework-6/)
- Полное решение: [`Homework-6/solutions.sql`](Homework-6/solutions.sql)
- Полное описание: [`Homework-6/README.md`](Homework-6/README.md)

Запуск внутри `psql`:

```sql
\i /work/Homework-6/solutions.sql
```

### Homework-7
- Директория: [`Homework-7/`](Homework-7/)
- Полное решение: [`Homework-7/solutions.sql`](Homework-7/solutions.sql)
- Полное описание: [`Homework-7/README.md`](Homework-7/README.md)

Запуск внутри `psql`:

```sql
\i /work/Homework-7/solutions.sql
```

### Homework-8
- Директория: [`Homework-8/`](Homework-8/)
- Полное решение: [`Homework-8/solutions.sql`](Homework-8/solutions.sql)
- Полное описание: [`Homework-8/README.md`](Homework-8/README.md)

Запуск внутри `psql`:

```sql
\i /work/Homework-8/solutions.sql
```

### Homework-9
- Директория: [`Homework-9/`](Homework-9/)
- Полное решение: [`Homework-9/solutions.sql`](Homework-9/solutions.sql)
- Полное описание: [`Homework-9/README.md`](Homework-9/README.md)

Запуск внутри `psql`:

```sql
\i /work/Homework-9/solutions.sql
```

### Homework-Final
- Директория: [`Homework-Final/`](Homework-Final/)
- Файлы финальной работы:
  - [`Homework-Final/schema.sql`](Homework-Final/schema.sql) — создание схемы/таблиц/триггеров/функций
  - [`Homework-Final/seed.sql`](Homework-Final/seed.sql) — наполнение данными
  - [`Homework-Final/queries.sql`](Homework-Final/queries.sql) — запросы для демонстрации
  - [`Homework-Final/README.md`](Homework-Final/README.md) — описание проекта и запросов

Запуск файлов внутри `psql` (в базе `ad_platform`):
```sql
-- \i /work/Homework-Final/schema.sql - Можно выполнить, но выполняется само при вызове скрипта bootstrap_ad_platform
-- \i /work/Homework-Final/seed.sql - Можно выполнить, но выполняется само при вызове скрипта bootstrap_ad_platform
\i /work/Homework-Final/queries.sql
```
